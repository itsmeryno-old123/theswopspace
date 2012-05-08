$(document).unbind('ready').ready(function() {
	defAddImgButtonClick();
})

function defAddImgButtonClick() {
	$("#imageadd").unbind('click').click(function() {
		var curId = $("#jQueryImgId").val();
		var newId = parseInt(curId) + 1;
		
		if (newId > 5) {
			alert("You can add a maximum of 5 images per item");	
		}
		else {
			var newP = "<p><input type=\"file\" name=\"image_" + newId + "\" size=\"60\"/></p>";
			$("#filecontrols").append(newP);
			$("#jQueryImgId").val(newId);
		}		
	});
}

function defImgGallery() {
	var p = location.pathname.split("/");
	var id = p[p.length-1];
	
	$("#gallery").imagegallery();
	
	$('#theme-switcher').change(function () {
	        var theme = $('#theme');
	        theme.prop(
	            'href',
	            theme.prop('href').replace(
	                /[\w\-]+\/jquery-ui.css/,
	                $(this).val() + '/jquery-ui.css'
	            )
	        );
	    });
	
    // Create a buttonset out of the checkbox options:
    //jQuery('#buttonset').buttonset();
    $('#gallery').imagegallery('option', {
    	show: 'blind',
    	hide: 'blind',
    	fullscreen: true,
    	slideshow: true && 5000
    });
	
	$.ajax({
		url: '/items/images/' + id
	}).done(function(data) {
		var gallery = $("#gallery"), url;
		var tmp = eval(data);
		
		for (i=0;i<tmp.length;i++) {
			img_url = '/image/get/' + tmp[i];
			$('<a rel="gallery"/>')
				.append($('<img>').prop('src', img_url))
				.prop('href', img_url)
				.appendTo(gallery);
		}
	})
}