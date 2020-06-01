<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8"/>
<title>1v1 Matchmaking Overlay</title>
<script src="https://cdn.jsdelivr.net/npm/ractive@1.3.1/ractive.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/ractive-transitions-fade"></script>
<style>
@font-face {font-family: "Britannic Bold"; src: url("//db.onlinewebfonts.com/t/8be4a2f403c2dc27187d892cca388e24.eot"); src: url("//db.onlinewebfonts.com/t/8be4a2f403c2dc27187d892cca388e24.eot?#iefix") format("embedded-opentype"), url("//db.onlinewebfonts.com/t/8be4a2f403c2dc27187d892cca388e24.woff2") format("woff2"), url("//db.onlinewebfonts.com/t/8be4a2f403c2dc27187d892cca388e24.woff") format("woff"), url("//db.onlinewebfonts.com/t/8be4a2f403c2dc27187d892cca388e24.ttf") format("truetype"), url("//db.onlinewebfonts.com/t/8be4a2f403c2dc27187d892cca388e24.svg#Britannic Bold") format("svg"); }

body {
	margin: 0px;
	padding: 0px;
}
</style>
</head>
<body>
<div id="app"></div>

<script id="template" type="text/ractive"></script>

<script>
window.onload = function() {
	var colors = {
		1: "rgba(0,120,215,1)",
		2: "rgba(236,9,9,1)",
		3: "rgba(3,251,3,1)",
		4: "rgba(255,241,0,1)",
		5: "rgba(24,241,243,1)",
		6: "rgba(254,3,251,1)",
		7: "rgba(211,211,211,1)",
		8: "rgba(246,149,20,1)"
	};
	
	// source: https://aoe2.net/api/strings?game=aoe2de&language=en
	var civs = [{"id":0,"string":"Aztecs"},{"id":1,"string":"Berbers"},{"id":2,"string":"Britons"},{"id":3,"string":"Bulgarians"},{"id":4,"string":"Burmese"},{"id":5,"string":"Byzantines"},{"id":6,"string":"Celts"},{"id":7,"string":"Chinese"},{"id":8,"string":"Cumans"},{"id":9,"string":"Ethiopians"},{"id":10,"string":"Franks"},{"id":11,"string":"Goths"},{"id":12,"string":"Huns"},{"id":13,"string":"Incas"},{"id":14,"string":"Indians"},{"id":15,"string":"Italians"},{"id":16,"string":"Japanese"},{"id":17,"string":"Khmer"},{"id":18,"string":"Koreans"},{"id":19,"string":"Lithuanians"},{"id":20,"string":"Magyars"},{"id":21,"string":"Malay"},{"id":22,"string":"Malians"},{"id":23,"string":"Mayans"},{"id":24,"string":"Mongols"},{"id":25,"string":"Persians"},{"id":26,"string":"Portuguese"},{"id":27,"string":"Saracens"},{"id":28,"string":"Slavs"},{"id":29,"string":"Spanish"},{"id":30,"string":"Tatars"},{"id":31,"string":"Teutons"},{"id":32,"string":"Turks"},{"id":33,"string":"Vietnamese"},{"id":34,"string":"Vikings"}];
	
	const suchFetch = (path, fetchOpts, params) => {
		var url = new URL(path)
		if (params != null) Object.keys(params).forEach(key => url.searchParams.append(key, params[key]))
		return fetch(url, fetchOpts);
	};
	
	const getParameterByName = function(name) {
		const url_object = new URL(window.location.href);
		return url_object.searchParams.get(name);
	}
	
	const periodicCheck = function() {
		/* check if ractive has been initialized yet */
		if (!window.ractive || !window.ractive.get()) { return; }
		var database = window.ractive.get('database');
		
		// check if polling is enabled and a player id is set
		console.log("Trying to get the current match from aoe2.net");
		// check every 30 seconds for updates in the aoe2.net api
		
		var params = (database.profileId && database.profileId > 0) ? {profile_id: database.profileId} : {steam_id: database.steamId};
		var fetchOpts = {headers: {Origin: 'https://share.polskafan.de'}};
		
		suchFetch('https://twitch.polskafan.de/aoe2obs/matchinfo', 
			fetchOpts=fetchOpts,
			params=params)
			.then((res) => {
				res.json().then((matchinfo) => {
					console.log(matchinfo);
					if (matchinfo.match && matchinfo.match.match_id && (matchinfo.match.match_id > 0) && (database.match.match_id != matchinfo.match.match_id)) {
						console.log("New data, updating!");
						// check if match is 1v1, if not ignore it
						if (matchinfo.match.num_players == 2) {
							thisRactive.set("database.match", matchinfo.match);
							thisRactive.set("database.players", matchinfo.players);
						}
					} else {
						console.log("No new data");
					}
				});
			}).catch((err) => console.log(err));
	}
	
	window.ractive = Ractive({
		target: "#app",
		template: "#template",
		data: {
			database: {
				players: [
					{
						wins: 70,
						losses: 30,
						rank: 1,
						rating: 2400,
						country: 'NO'
					},
					{
						wins: 71,
						losses: 29,
						rank: 2,
						rating: 2300,
						country: 'ES'
					},
				],
				match: {
					num_players: 2,
					leaderboard_id: 3,
					players: [
						{
							name: 'TheViper',
							civ: 3,
							color: 4,
							profile_id: 196240
						},
						{
							name: 'TaToH',
							civ: 5,
							color: 1,
							profile_id: 197388
						},
					]
				},
			},
			f: {
				winrate: function(p) {
					return (100*p.wins/(p.wins+p.losses)).toFixed(0);
				},
				color: function(c) {
					return colors[c];
				},
				civImage: function(p, orientation) {
					var civname = civs[p.civ].string.toLowerCase();
					return "img/civs/"+orientation+"/"+civname+"-DE.png";
				},
				flagImage: function(p) {
					var country = p.country.toLowerCase();
					return "https://raw.githubusercontent.com/lipis/flag-icon-css/master/flags/1x1/"+country+".svg";
				},
				gameType2: function(m) {
					console.log("gt", m);
					if (m.num_players == 2) {
						return "1v1";
					}
				},
				gameType: function(m) {
					console.log(m);
					if (m.leaderboard_id == 1 || m.leaderboard_id == 2) {
						return "DM";
					}
					if (m.leaderboard_id == 3 || m.leaderboard_id == 4) {
						return "RM";
					}
					return "";
				}
			}
		},
		onrender: function() {
			thisRactive = this;
			
			// get url parameters
			thisRactive.set('database.steamId', getParameterByName('steam_id'));
			thisRactive.set('database.profileId', getParameterByName('profile_id'));
			
			// start polling
			setTimeout(periodicCheck, 500);
			window.periodicCheckInterval = setInterval(periodicCheck, 30*1000);
		}
	});
}
</script>
</body>
</html>