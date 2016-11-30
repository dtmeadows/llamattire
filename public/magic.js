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
			$('#stripe-checkout').attr("data-amount", sum)
			$('.stripe-button-el span').text("Pay Cart: $" + sum/100)
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

	/* script moved from html*/

	var handler = StripeCheckout.configure({
	  key: 'pk_test_zdQoXfpUzWPgsEn8v4z0wN5L',
	  locale: 'auto',
	  name: 'LlamaAttire',
	  description: 'My test thang',
	  token: function(token) {
	    $('input#stripeToken').val(token.id);
	    $('#checkout-form').submit();
	  }
	});

	$('#payment-button').on('click', function(e) {

		e.preventDefault();

		/*$('#error_explanation').html('');*/

		var amount = $('#checkout-form').attr("data-amount"); 

		amount = parseFloat(amount);

		/*if (isNaN(amount)) {
	 		$('#error_explanation').html('<p>Please enter a valid amount in USD ($).</p>');
		}
		else if (amount < 5.00) {
			$('#error_explanation').html('<p>Donation amount must be at least $5.</p>');
		}
		else {*/
			amount = amount; // Needs to be an integer!
	    	handler.open({
	    	amount: Math.round(amount)
	    })
		/*}*/
	});

});


