// ANALYSIS PASS
OfflineProcess().putKr(\analyze, {
	|in|
	var out, fft, geoMean, arithMean, result;

	fft = FFT(LocalBuf(512), in);
	out = Demand.kr(
		fft > -1,
		0,
		UnpackFFT(fft, 512)
	);
	out = out.max(0.01);

	geoMean = out;
	geoMean = geoMean.geoMean();

	arithMean = out.mean;

	result = [
		geoMean,
		A2K.kr(BLowPass4.ar(K2A.ar(geoMean), 10, 1)),
		PeakFollower.kr(in, 0.9) / 10,
	];
	result;
});
