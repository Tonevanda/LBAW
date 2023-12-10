function addEventListeners() {
  let cartDeleter = document.querySelectorAll('form.remove_cart');
  [].forEach.call(cartDeleter, function(deleter){
    deleter.addEventListener('submit', deleteCartProductRequest);
  });

  let wishlistDeleter = document.querySelectorAll('form.remove_wishlist');
  [].forEach.call(wishlistDeleter, function(deleter){
    deleter.addEventListener('submit', deleteWishlistProductRequest);
  });
  let cartCreator = document.querySelectorAll('form.add_cart');
  [].forEach.call(cartCreator, function(creator){
    creator.addEventListener('submit', createCartProductRequest);
  });

  let wishlistCreator = document.querySelectorAll('form.add_wishlist');
  [].forEach.call(wishlistCreator, function(creator){
    creator.addEventListener('submit', createWishlistProductRequest);
  });

  let priceFilter = document.querySelector('form.products_search input[name=price]');
  let priceShow = document.querySelector('form.products_search div');
  if(priceFilter != null && priceShow != null){
    if(priceShow.textContent == 0)priceShow.textContent = `no restrictions`;
    priceFilter.addEventListener('input', function () {
      priceShow.textContent = this.value;
      if(priceShow.textContent == 0){
        priceShow.textContent = `no restrictions`;
      }
    });
  }


  let profile_pic_edit_icon = document.querySelector('.user_image i');

  let profile_pic_input = document.querySelector('input[name=profile_picture]');

  let profile_pic_form = document.querySelector('form.profile_pic');





  if(profile_pic_form != null){
    profile_pic_form.addEventListener('submit', updateProfilePictureRequest);
  }

  if(profile_pic_edit_icon != null){
    profile_pic_edit_icon.addEventListener('click', function(){
      profile_pic_input.click();
    });
  }

  if(profile_pic_input != null){
    profile_pic_input.addEventListener('change', function(event){
      let update_pic_button = profile_pic_form.querySelector('input[name=update_pic');
      update_pic_button.click();
    });
  }


 
   let reportCreator = document.querySelectorAll('form.report_review');
  [].forEach.call(reportCreator, function(creator){
    creator.addEventListener('submit', createReportRequest);
  });

  let deleteReview = document.querySelectorAll('form.delete_review');
  [].forEach.call(deleteReview, function(deleter){
    deleter.addEventListener('submit', deleteReviewRequest);
  });

  let reviewEditIcon= document.querySelector('li i');
  if(reviewEditIcon != null)reviewEditIcon.addEventListener('click', editReview);

  let itemCreators = document.querySelectorAll('article.card form.new_item');
  [].forEach.call(itemCreators, function(creator) {
    creator.addEventListener('submit', sendCreateItemRequest);
  });

  let itemDeleters = document.querySelectorAll('article.card li a.delete');
  [].forEach.call(itemDeleters, function(deleter) {
    deleter.addEventListener('click', sendDeleteItemRequest);
  });

  let cardDeleters = document.querySelectorAll('article.card header a.delete');
  [].forEach.call(cardDeleters, function(deleter) {
    deleter.addEventListener('click', sendDeleteCardRequest);
  });

  let cardCreator = document.querySelector('article.card form.new_card');
  if (cardCreator != null)
    cardCreator.addEventListener('submit', sendCreateCardRequest);
  }
  
  function encodeForAjax(data) {
    if (data == null) return null;
    return Object.keys(data).map(function(k){
      return encodeURIComponent(k) + '=' + encodeURIComponent(data[k])
    }).join('&');
  }


  function sendAjaxRequest(method, url, data, handler) {
    let request = new XMLHttpRequest();
    
    request.open(method, url, true);
    request.setRequestHeader('X-CSRF-TOKEN', document.querySelector('meta[name="csrf-token"]').content);
    request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    request.addEventListener('load', handler);
    request.send(encodeForAjax(data));
  }


  function sendAjaxRequestImage(method, url, data, handler){
    let request = new XMLHttpRequest();
    
    request.open(method, url, true);
    request.setRequestHeader('X-CSRF-TOKEN', document.querySelector('meta[name="csrf-token"]').content);
    request.addEventListener('load', handler);
    request.send(data);
  }
  
  function editReview(){
    document.querySelector('li textarea[name=description]').readOnly = false; 
    let button= document.querySelector('li button[name=update-review]');
    button.classList.toggle('visible');
    if(this.classList.contains("fa-edit")){
      this.classList.remove("fa-edit");
      this.classList.add("fa-times");
      document.querySelector('li form').addEventListener('submit', updateReviewRequest);
    }
    else{
      this.classList.remove("fa-times");
      this.classList.add("fa-edit");
  }
}
function updateReviewRequest(event){
  console.log(this);
  let review_id = this.querySelector('input[name=review_id]').value;
  let description = this.querySelector('textarea[name=description]').value;
  sendAjaxRequest('put', '/review/'+review_id, {review_id: review_id, description: description}, reviewHandler);
  event.preventDefault();
}

function createReportRequest(event){
  let review_id = this.querySelector('input[name=review_id]').value;
  let product_id = this.querySelector('input[name=product_id]').value;
  console.log(review_id, product_id);
  sendAjaxRequest('post', '/review/'+review_id, {review_id: review_id, product_id: product_id}, createReportHandler);
  event.preventDefault();
}

function deleteReviewRequest(event){
  let review_id = this.querySelector('input[name=review_id]').value;
  let product_id = this.querySelector('input[name=product_id]').value;
  sendAjaxRequest('delete', '/review/'+review_id, {review_id: review_id, product_id: product_id}, deleteReviewHandler);
  event.preventDefault();
}

function createWishlistProductRequest(event){
  let user_id = this.querySelector('input[name=user_id]').value;
  let product_id = this.querySelector('input[name=product_id]').value;
  sendAjaxRequest('post', '/api/wishlist/'+user_id, {product_id: product_id}, createCartProductHandler);
  event.preventDefault();
}
function createCartProductRequest(event){
  let user_id = this.querySelector('input[name=user_id]').value;
  let product_id = this.querySelector('input[name=product_id]').value;

  sendAjaxRequest('post', '/api/shopping-cart/'+user_id, {product_id: product_id}, createCartProductHandler);
  event.preventDefault();
}

function deleteWishlistProductRequest(event){
  console.log('ola');
  let user_id = this.querySelector('input[name=user_id]').value;
  let wishlist_id = this.querySelector('input[name=wishlist_id]').value;
  sendAjaxRequest('delete', '/api/wishlist/'+user_id, {wishlist_id: wishlist_id}, deleteWishlistProductHandler);
  event.preventDefault();
}
function deleteCartProductRequest(event){
  let user_id = this.querySelector('input[name=user_id]').value;
  let cart_id = this.querySelector('input[name=cart_id]').value;
  sendAjaxRequest('delete', '/api/shopping-cart/'+user_id, {cart_id: cart_id}, deleteCartProductHandler);
  event.preventDefault();
}

function updateProfilePictureRequest(event){
  console.log(this);

  let file = this.querySelector('input[name=profile_picture]').files[0];
  let old_file = this.querySelector('input[name=old_profile_picture]').value;
  let user_id = this.querySelector('input[name=user_id]').value;

  let formData = new FormData();
  formData.append('profile_picture', file);
  formData.append('old_profile_picture', old_file);


  sendAjaxRequestImage('post', '/api/users/'+user_id, formData, updateProfilePictureHandler);

  event.preventDefault();
}

function deleteReviewHandler(){
  if(this.status == 200){
    console.log("deleted review");
    let response = JSON.parse(this.responseText);
    let deletion_target = document.querySelector('li[data-id="' + response + '"]');
    deletion_target.remove();
  }
}

function reviewHandler(){
  if(this.status == 201){
    console.log("reported");
  }
  else if(this.status == 200){
    console.log("updated review");
    
  }
}

function createReportHandler(){
  if(this.status == 201){
    console.log("reported");
  }
}
  
function createCartProductHandler(){
  if(this.status == 201){
    console.log("added to shopping cart");
    
  }
}

function deleteCartProductHandler(){
  if(this.status == 200){
    console.log("removed from shopping cart");
    let response = JSON.parse(this.responseText);
    let deletion_target = document.querySelector('div[data-id="' + response + '"]');
    let deletion_price = deletion_target.querySelector('a p:last-child').textContent;
    let new_total_price = document.querySelector('tr:last-child td:first-child');
    let new_total_quantity = document.querySelector('tr:last-child td:last-child');
    new_total_price.textContent= new_total_price.textContent-deletion_price;
    new_total_quantity.textContent = new_total_quantity.textContent-1;
    deletion_target.remove();
  }
}

function deleteWishlistProductHandler(){
  if(this.status == 200){
    console.log(this)
    console.log("removed from wishlist");
    let response = JSON.parse(this.responseText);
    let deletion_target = document.querySelector('div[data-id="' + response + '"]');
    deletion_target.remove();
  }
}

function updateProfilePictureHandler(){
  if(this.status == 200){
    let response = JSON.parse(this.responseText);
    let profile_pic = document.querySelector('form.profile_pic img');
    let old_profile_pic_input = document.querySelector('form.profile_pic input[name=old_profile_picture]');
    var imagePath = response;
    var imageUrl = assetBaseUrl + '/' + imagePath;
    profile_pic.setAttribute('src', imageUrl);

    old_profile_pic_input.value = response;
  }
}
  
    // Function to show the popup
    function showPopup() {
      var popup = document.getElementById('popup');
      var overlay = document.getElementById('overlay');

      popup.style.display = 'block';
      overlay.style.display = 'block';

      // Hide the popup after 3 seconds (adjust as needed)
      setTimeout(function () {
          hidePopup();
      }, 1500);
  }

  // Function to hide the popup
  function hidePopup() {
      var popup = document.getElementById('popup');
      var overlay = document.getElementById('overlay');

      // Hiding the popup and overlay
      popup.style.display = 'none';
      overlay.style.display = 'none';
  }


  function toggleMenu() {
    var miniMenu = document.getElementById('miniMenu');
    var userButton = document.querySelector('.user-button');
  
    // Toggle the 'active' class to control visibility
    miniMenu.classList.toggle('active');
  
    if (miniMenu.classList.contains('active')) {
      // Calculate position when showing the menu
      var rect = userButton.getBoundingClientRect();
      var offsetLeft = (window.innerWidth - rect.left - rect.width) / 2; // Adjust this offset as needed
      miniMenu.style.top = rect.bottom + window.scrollY + 12 + 'px';
      miniMenu.style.left = rect.left - miniMenu.offsetWidth + offsetLeft + 12 + 'px';
    }
  }
  function showMultiStepModal() {
    var modal = document.getElementById('multiStepModal');
    modal.style.display = 'block';
    showStep(1); // Show the first step initially
}

function hideMultiStepModal() {
    var modal = document.getElementById('multiStepModal');
    modal.style.display = 'none';
}

function showStep(step) {
    // Hide all steps
    for (let i = 1; i <= 4; i++) {
        document.getElementById('step' + i).style.display = 'none';
    }

    // Show the selected step
    document.getElementById('step' + step).style.display = 'block';
}

document.addEventListener('DOMContentLoaded', function () {
    // Add event listeners or other initialization code here if needed
});

  // Your JavaScript code
  document.getElementById('heartButton').addEventListener('click', function() {
    this.classList.toggle('clicked');
});

addEventListeners();
  
  

