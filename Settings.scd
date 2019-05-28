Event.make({
	~input 			= "~/Documents/_sounds/gaza/test-1.wav".standardizePath;
	~resampleWindow = 256;
	~resampleStep	= 1/4;
	~noiseLevels    = (-20, -14..34) ++ [-inf];
	~noiseSettings  = ~noiseLevels.collect({
		|level|
		(
			db: level,
			low: 20,
			hi: 7000
		)
	});
})