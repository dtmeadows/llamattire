$(document).ready(
	function(){

	console.log("loaded and ready!")

	setTimeout(function (){
		$('#welcome-rapper').slideDown()
	}, 500);

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
  		$('.product-checks').each(function() {
  			if ($(this).is(':checked')) {

  			sum += parseInt($(this).data("amount"))
  		}	
  			

  		})

		if (sum > 0) { 
			$('#cart-total').text("Your cart total is $" + sum/100); 
			$('#checkout-button').slideDown();
  			}
		else {
			$('#cart-total').text("Cart is currently empty. Add some items!")
			$('#checkout-button').slideUp();
  			}
  		console.log("loggin sum... " + sum)
  		;
  	}

	$('#cart-total').text(sum)
 
	$( '.product-checks' ).on( "click", sumCart );

});


