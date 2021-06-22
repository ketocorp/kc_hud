let status = [];
let radarIsShowing = true;
let isPaused = false;
let minimapData;
let blinking = [];
let style = 'vertical'
let renderStatus = function () {
	for (let i = 0; i < status.length; i++) {
		var bar = $('.bar_' + status[i].name);
		if (!status[i].visible) {
			DisableBlink(status[i].name);
			bar.hide();
			continue;
		}
		bar.show();

		bar.find('.status_val')
		.css({
			'width': (Math.round(status[i].percent)) + '%'
		});
		bar.find('.status_val_text').text(Math.round(status[i].percent) + '%');
		if(status[i].blinkOnLow && Math.round(status[i].percent) < 25)
		{
			EnableBlink(status[i].name);
		}
		else if(status[i].blinkOnHigh && Math.round(status[i].percent) > 75)
		{
			EnableBlink(status[i].name);
		}
		else
		{
			DisableBlink(status[i].name);
		}
	}
};
this.EnableBlink = function(name)
{
	if(blinking[name] === undefined)
	{
		blinking[name] = window.setInterval(function(){
			var baricon = $('.bar_' + name + ' .icon');
			if(baricon.is(":hidden")){
				baricon.show();
			}else{
				baricon.hide();
			}
		}, 1000);
	}
}
this.DisableBlink = function(name)
{
	if(blinking[name] !== undefined)
	{
		var baricon = $('.bar_' + name).find('.icon');
		baricon.show();
		window.clearInterval(blinking[name]);
		delete blinking[name];
	}
}

window.onData = function (data) {
	if (data.update) {
		status.length = 0;
		for (let i = 0; i < data.status.length; i++) {
			status.push(data.status[i]);
		}
		renderStatus();
	}
	if(data.paused)
	{
		isPaused = data.value;
		renderUI();
	}
	if(data.disableHUD)
	{
		var huds = ['compasandstreet','es_ui','es_extended'];
		var huds_mode3 = ['es_extended'];
		var huds_mode4 = ['es_ui','es_extended'];
		var childhuds = { 'es_ui': [ '#money' ], 'es_extended': [ '#hud' ] };
		var childhuds_mode3 = { 'es_extended': [ 'job', 'job2','society_money' , 'society_money2'] };
		var childhuds_mode4 = { 'es_ui': [ '#money' ], 'es_extended': [ 'job', 'job2', 'society_money' , 'society_money2', 'account_bank', 'account_black_money' ] };
	
		$(window.top.document.body).find('iframe').each(function(ix,elem){
			if(childhuds[elem.name] !== undefined)
			{
				$(childhuds[elem.name]).each(function(ij,chilelem)
				{
					$(elem.contentDocument).find(chilelem).show();
				});
				if(childhuds_mode4[elem.name] !== undefined)
				{
					$(childhuds_mode4[elem.name]).each(function(ij,childelem)
					{
						if(elem.name == 'es_extended')
						{
							elem.contentWindow.postMessage({action:'enableHUDElement', name: childelem},'*');
						}
					});
				}
			}
			$(elem).show();
		});
		if(data.value == "1")
		{
			$(window.top.document.body).find('iframe').each(function(ix,elem){
				$(elem).hide();
			});
		}
	}
	if(data.setStyle)
	{
		style = data.value;
		renderUI();
	}
	if(data.radarChanged)
	{
		radarIsShowing = data.isShowing;
		renderUI();
	}
	if (data.setMinimap) {
		minimapData = data.minimap;
		renderUI();
	}
	if (data.setDefcon) {
		this.SetDefCon(data.defconLevel);
	}
	if (data.hideDefcon) {
		this.HideDefCon();
	}
	if(data.updateVehicle)
	{
		this.updateVehicle(data);
	}
	if(data.updateJobCounter)
	{
		this.updateJobCounter(data);
	}
	if(data.updateVoice)
	{
		this.updateVoice(data);
	}
	if(data.updateZoneUI)
	{
		this.updateZoneUI(data);
	}
	if(data.updateJobCounterOpacity)
	{
		this.updateJobCounterOpacity(data);
	}
	if(data.showBanner)
	{
		this.showBanner(data);
	}
};
this.renderUI = function(){
	if(style == 'horizontal')
	{
		$('.vertical').hide();
		$('.horizontal').show();
	}
	else
	{
		$('.vertical').show();
		$('.horizontal').hide();
	}
	if(isPaused)
	{
		$('#status_bar').hide();
	}
	else
	{
		$('#status_bar').show();
	}
	if(radarIsShowing)
	{
		$('#status_bar').css({'position': 'absolute',
			'bottom': 0,
			'left': fixW(minimapData.x) + fixW(minimapData.width)
			});
	}
	else
	{
		$('#status_bar').css({'position': 'absolute',
			'bottom': 0,
			'left': 0
			});
	}
}
this.fixH = function(size)
{
	return size * screen.height;
}
this.fixW = function(size)
{
	return size * screen.width;
}
this.bannerQueue = [];
this.bannerShowing = false;
this.showBanner = function(data)
{
	if(!this.bannerShowing && this.bannerQueue.length == 0)
	{
		this.bannerShowing = true;
		this.showBannerUI(data);
	}
	else
	{
		this.bannerQueue.push(data);
	}
}
this.showBannerUI = function(data)
{
	var that = this;
	$('.banner').css({'background-image': "url('https://images.forasterosrp.com/paneles/" + data.banner + ".png')"});
	if(data.style == 'dark')
	{
		$('.bannertext').removeClass('bannertextlight');
	}
	else
	{
		$('.bannertext').addClass('bannertextlight');
	}
	$('.bannertext').text(data.msg);
	$('.banner').slideDown(function(){
		setTimeout(function(){
			$('.banner').slideUp(function(){
				if(that.bannerQueue.length > 0)
				{
					var data = that.bannerQueue.pop();
					that.showBannerUI(data);
				}
				else
				{
					that.bannerShowing = false;
				}
			});
		}, data.timeout * 1000);
	});
}
this.updateJobCounter = function(data)
{
	$('.jobcountvalue_police').text(data.value.cops_count);
	$('.jobcountvalue_ambulance').text(data.value.sani_count);
	$('.jobcountvalue_mechanic').text(data.value.meca_count);
	$('.jobcountvalue_taxi').text(data.value.taxi_count);
	$('.jobcountvalue_badulake').text(data.value.badu_count);
	$('.jobcountvalue_id').text(data.value.playerId);
}
this.updateVoice = function(data)
{
	if(data.value.enable)
	{
		this.console.log('enable')
		$('.voicetable').show();
	}
	if(data.value.disable)
	{
		this.console.log('disable')
		$('.voicetable').hide();
	}
	if(data.value.level)
	{
		$('.voicelevel').text(data.value.level);
	}
	if(data.value.color)
	{
		$('.voicelevel').css('color', data.value.color);
	}
}
this.updateZoneUI = function(data)
{
	$('.zoneUI').text(data.value.zone);
	if(data.value.color)
	{
		$('.zoneUI').css('color', data.value.color);
	}
}
this.updateJobCounterOpacity = function(data)
{
	$('.voiceandjobtable').css('opacity', data.value);
}
this.updateVehicle = function(data) {
	var vehicleInfo = document.querySelector('.info.vehicle');
	var vehicleSeatbelt = document.querySelector('#seatbelt');
	var vehicleLights = document.querySelector('#lights');
	var vehicleSignals = document.querySelector('#signals');
	var vehicleFuel = document.querySelector('#fuel');
	var vehicleCruiser = document.querySelector('#vehicle-speed strong');
	var vehicleDamage = document.querySelector('#damage');
	
	if (data.status == true) {	
		if (vehicleInfo.classList.contains('inactive')) {
			vehicleInfo.classList.remove('inactive');
			vehicleInfo.classList.add('active');
		}

	
		if (vehicleInfo.classList.contains('updated') == false) {

			var vehicleSpeedUnit = data.config.speedUnit.slice(0,2)+'/'+data.config.speedUnit.slice(-1);
			var vehicleAverageSpeed = Math.ceil(data.config.maxSpeed / 6);

			vehicleInfo.classList.add('updated');
			saferInnerHTML(vehicleCruiser,vehicleSpeedUnit);

		}

		saferInnerHTML(document.querySelector('#KM span'), data.currentKM);

		saferInnerHTML(document.querySelector('#vehicle-speed span'), data.speed);

		

		if ( (data.seatbelt.status == true) && (vehicleSeatbelt.classList.contains('on') == false) ) {
			vehicleSeatbelt.classList.remove('off');
			vehicleSeatbelt.classList.add('on');
		}
		else if ( (data.seatbelt.status == false) && (vehicleSeatbelt.classList.contains('off') == false) ) {
			vehicleSeatbelt.classList.remove('on');
			vehicleSeatbelt.classList.add('off');
		}
		if(data.haveBelt)
		{
			$('#seatbelt').show();
		}
		else
		{
			$('#seatbelt').hide();
		}

		if (vehicleCruiser.classList.contains(data.cruiser) == false) {
			vehicleCruiser.classList.remove('on','off');
			vehicleCruiser.classList.add(data.cruiser);
		}
		
		
		vehicleFuel.querySelector('span').style.height = data.fuel+'%';

		if (data.fuel <= 35) {
			if (vehicleFuel.classList.contains('dying') == false) { vehicleFuel.classList.add('dying');	}
		}
		else { vehicleFuel.classList.remove('dying'); }


		

		

	}
	else {
		if (vehicleInfo.classList.contains('active')) {
			vehicleSeatbelt.classList.remove('on');
			vehicleCruiser.classList.remove('on');

			vehicleInfo.classList.remove('active');
			vehicleInfo.classList.add('inactive');
		}

	}
}
window.onload = function (e) {
	window.addEventListener('message', function (event) {
		onData(event.data);
	});
};
