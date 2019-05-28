{
	|name, run, windowSize=256, windowStep=(1/4)|
	var i = 0, max = 0, resultMax, resultMaxMax, resultMaxMin, resultDownsampled, lane;

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
		i = i + (windowSize * windowStep);
	};

	resultDownsampled;
}
