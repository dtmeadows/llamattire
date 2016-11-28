$(document).ready(
	function(){

	console.log("loaded and ready!")

	$('#welcome-message').fadeIn()

	$('#welcome-message').click(
		function() {
		$(this).hide();
		$('#welcome-rapper').slideUp();
	});

	$('#secret-button').click(
		function() {
			$('#llama-party').fadeIn(3000);
			$('#llama-party').fadeOut(3000);
		}
		)

 	var sum;

	var sumCart = function() {
		sum = 0;
  		$( '.product-checks' ).each(function() {
  			if ($(this).is(':checked')) {

  			sum += parseInt($(this).data("amount"))
  		}
  			$('#cart-total').text(sum)
  			console.log(sum)
  		});
  	}

	$('#cart-total').text(sum)
 
	$( '.product-checks' ).on( "click", sumCart );
});

