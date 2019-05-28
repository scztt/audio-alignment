// ADD NOISE AND OFFSET
OfflineProcess().putAr(\noise, {
	|in, time, db, hi, low|
	var noise;
	noise = WhiteNoise.ar(1) * db.dbamp;
	noise = BLowPass4.ar(noise, hi);
	noise = BHiPass4.ar(noise, low);
	noise + in;
});
