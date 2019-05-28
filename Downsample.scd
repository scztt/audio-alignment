{
	|name, run|
	var i = 0, windowSize = 256, max = 0, resultMax, resultMaxMax, resultMaxMin, resultDownsampled, lane;

	resultMax = run.resultData(name);
	resultMax = resultMax.collect(_[10..]);
	resultMaxMin = resultMax.collect(_.minItem);
	resultMaxMax = resultMax.collect(_.maxItem);
	resultMax = resultMax.linlin(resultMaxMin, resultMaxMax, 0, 1);
	resultMax = resultMax[0];

	resultDownsampled = List();
	while { (i + windowSize) < resultMax.size } {
		max = 0;
		windowSize.do {
			|j|
			max = max.max(resultMax[i+j]);
		};
		resultDownsampled.add(max);
		i = i + (windowSize / 4);
	};

	resultDownsampled;
}
