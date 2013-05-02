$(document).ready(function() {
	$('#action-form input#btn-hit').on("click", function() {
		$.ajax({
			type: 'POST',
			url: '/game/hit',
			success: function(x) {
				$('#game').html(x);
			}
		});
		return false;
	});
	$('#action-form input#btn-stay').on("click", function() {
		$.ajax({
			type: 'POST',
			url: '/game/stay',
			success: function(x) {
				$('#game').html(x);
			}
		});
		return false;
	});
});