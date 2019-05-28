Event.make({
	~input 			= "~/Documents/_sounds/gaza/test-1.wav".standardizePath;
	~iterations 	= 10;
	~timeOffsets 	= ~iterations.collect { 20.rand };
	~noiseSettings  = ~iterations.collect({
		|i|
		(db: -20 + (i * 6), low: 20, hi: 7000)
	}) ++ [(db: -inf, low: 20, hi: 7000)]  // no noise
})