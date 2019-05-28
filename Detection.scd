(
// Log(\OfflineProcess).level = \debug;

~settings = Require("Settings");
~soundFile = SoundFile();
~soundFile.openRead(~settings.input);
~settings.sampleMultiplier = (
	~soundFile.sampleRate
	/ (~settings.resampleWindow * ~settings.resampleStep)
	/ 64 // Control block size
);
~soundFile.close();

fork({
	var done;

	/////////////////////////////////////////////////////////////////////////////////////
	// ADD NOISE AND OFFSET
	~noise = Require("1-AddNoise");
	~noiseSettings = List();

	~runs = ~settings.noiseSettings.collect {
		|noiseSettings, i|
		"Run %, settings: %".format(i, noiseSettings).postln;

		OfflineProcessRun(
			parent: 	~noise,
			fileOrTime:	~settings.input,
			args: (
				noise: noiseSettings
			)
		).run
	};

	// // One more run with no noise - this should be the best case for matching
	// ~runs.add(OfflineProcessRun(
	// 	parent: 	~noise,
	// 	fileOrTime:	~settings.input,
	// 	args: (
	// 		noise: (db:-inf, lo:22000, hi:1)
	// 	)
	// ).run);

	Deferred.usingAll(~runs.collect(_.deferred)).wait();
	"DONE".postln;
	/////////////////////////////////////////////////////////////////////////////////////



	/////////////////////////////////////////////////////////////////////////////////////
	// ANALYSIS PASS
	~analyze = Require("2-Analyze");
	~analyzeRuns = ~runs.collect {
		|inRun, i|
		"Run %, analyze".format(i).postln;
		OfflineProcessRun(
			parent:		~analyze,
			fileOrTime:	inRun.resultFile(\noise).postln
		).run();
	};

	Deferred.usingAll(~analyzeRuns.collect(_.deferred)).wait();
	"DONE".postln;
	/////////////////////////////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////////
	// RESAMPLING
	"RESAMPLING...".postln;

	~downsampleFunc = Require("downsample");
	~downsampledData = ~analyzeRuns.collect(
		~downsampleFunc.value(\analyze, _, ~settings.resampleWindow, ~settings.resampleStep)
	);
	/////////////////////////////////////////////////////////////////////////////////////



	/////////////////////////////////////////////////////////////////////////////////////
	// EXECUTE TESTS
	~tests = Require("TestCases");
	~comparisons = ();
	~tests.collect {
		|test, testIndex|
		var iteration, start, end, data, comparisons;
		#iteration, start, end = test;

		"\n\nTesting iteration %, range %s - %s against all other iterations".format(
			iteration, start, end).postln;

		start = (start * ~settings.sampleMultiplier).floor.asInteger;
		end = (end * ~settings.sampleMultiplier).floor.asInteger;

		data = ~downsampledData[iteration][start..end];

		comparisons = (0..~downsampledData.size-1);
		comparisons.remove(iteration);

		comparisons.collect {
			|comparison|
			var startTarget = 0, maxCorr = 0, maxTarget = 0, corr, compare;
			"Comparing against iteration %....".format(comparison).postln;

			while { startTarget < (~downsampledData[comparison].size - data.size - 1) } {
				compare = ~downsampledData[comparison][startTarget..startTarget+data.size-1];
				corr = data.corr(compare);

				if ((corr > 0.2) && (corr > maxCorr)) {
					"    Found new max correlation: % (at %s)".format(
						corr,
						startTarget / ~settings.sampleMultiplier
					).postln;
					maxCorr = corr;
					maxTarget = startTarget;
				};

				startTarget = startTarget + 1;
			};

			maxTarget = maxTarget / ~settings.sampleMultiplier;
			">> Best match for comparing % against %: %s offset".format(
				iteration, comparison,
				maxTarget
			).postln;

			~comparisons[testIndex] = ~comparisons[testIndex] ?? {()};
			~comparisons[testIndex][comparison] = (
				test: test,
				result: maxTarget,
				comparison: comparison
			)
		}
	};
	/////////////////////////////////////////////////////////////////////////////////////




	/////////////////////////////////////////////////////////////////////////////////////
	// DISPLAY RESULTS

	~overallView = ScrollTopView();
	~overallView.canvas = View();
	~overallView.canvas.layout = VLayout().margins_(10).spacing_(0);
	~overallView.canvas.layout.add(
		ToolBar(
			StaticText().string_("Test: "),
			~testMenu = Menu(),
		)
	);
	~overallView.canvas.layout.add(~lanes = View());
	~lanes.layout_(VLayout());
	~overallView.canvas.layout.add(nil);

	~comparisons.keys.asArray.sort.do {
		|index|
		~testMenu.addAction(MenuAction(
			~comparisons[index].choose.test.asString,
			{
				|action|
				~testValue = index;
				~testMenu.string = action.string;
				~updateView.();
			}
		));
	};

	~updateView = {
		var test;
		~lanes.children.do(_.remove);

		// Show our ground-truth without noise first
		test = ~comparisons[~testValue];

		~views = [
			(
				start: 0,
				test: [~runs.size - 1, 0, ~runs.last.duration],
				color: Color.blue(0.8, 0.9).sat_(0.4)
			),
			(
				start: ~comparisons[~testValue].choose.test[1],
				test: ~comparisons[~testValue].choose.test,
				color: Color.green(0.8, 0.9),
				label: "Actual alignment"
			)
		] ++ ~comparisons[~testValue].keys.asArray.sort.collect {
			|index|
			var comparison = ~comparisons[~testValue][index];
			(
				start: comparison.result,
				test: comparison.test,
				compareIndex: comparison.comparison,
				label: "Comparing against: %".format(~settings.noiseSettings[comparison.comparison])
			)
		};

		~views.do {
			|item, i|
			var against, guess, iteration, start, end, lane, dataIndex;

			#iteration, start, end = item.test;
			guess = item.start;
			dataIndex = item.compareIndex ? iteration;
			dataIndex.postln;

			start = (start * ~settings.sampleMultiplier).floor.asInteger;
			end = (end * ~settings.sampleMultiplier).floor.asInteger;
			guess = (guess * ~settings.sampleMultiplier).floor.asInteger;

			~view = SoundFileView();
			~view.gridOn = false;
			~view.fixedWidth_(end-start);
			~view.fixedHeight_(100);
			~view.setData(~downsampledData[dataIndex][start..end]);
			~view.background_(Color.grey(0.8, 0.9));
			~view.waveColors_([ Color.black ]);
			if (item.color.notNil) {
				~view.background = item.color;
			};

			lane = View().fixedWidth_(2000);
			lane.layout = HLayout().margins_(0).spacing_(0);
			lane.layout.add(guess);
			lane.layout.add(~view);
			lane.layout.add(nil);

			if (item.label.notNil) {
				~lanes.layout.add(StaticText()
					.font_(Font(size:16))
					.string_(item.label)
				);
			};
			~lanes.layout.add(lane);
		};
	};

	~testMenu.actions[0].action.(~testMenu.actions[0]);

	~overallView.front.minSize_(1200@600);
	/////////////////////////////////////////////////////////////////////////////////////



}, AppClock)
);


