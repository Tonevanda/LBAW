let money;

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
    if(priceShow.textContent == 500)priceShow.textContent = `MAX`;
    priceFilter.addEventListener('input', function () {
      priceShow.textContent = this.value;
      if(priceShow.textContent == 500){
        priceShow.textContent = `MAX`;
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

  let deleteReview = document.querySelector('form.delete_review');
  if(deleteReview != null){
    deleteReview.addEventListener('submit', deleteReviewRequest);
  }

  let reviewEditIcon= document.querySelector('li i');
  if(reviewEditIcon != null)reviewEditIcon.addEventListener('click', editReview);

  let reviewCreate = document.querySelector('form.add_review');
  if(reviewCreate != null){
    reviewCreate.addEventListener('submit', createReviewRequest);
  }
  let fullScreenPopup = document.getElementById('fullScreenPopup');
  let fullScreenPopup2 = document.getElementById('fullScreenPopup2');

  let popupButtons = document.querySelectorAll('button[name=show_popup]');
  [].forEach.call(popupButtons, function(button){
    button.addEventListener('click', function(event){
      event.preventDefault();
      money = button.getAttribute('data-money');
      showFullScreenPopup.bind(fullScreenPopup)();
    });
  });

  let popupButtons2 = document.querySelectorAll('button[name=show_popup2]');
  [].forEach.call(popupButtons2, function(button){
    button.addEventListener('click', function(event){
      event.preventDefault();
      if(money != null){
        document.querySelector('div#fullScreenPopup2 form div div.column:nth-child(2) p').textContent = money;
        const payment_method = document.querySelector('div#fullScreenPopup form select[name=payment_type]').value;
        const name = document.querySelector('div#fullScreenPopup form input[name=name]').value;

        let payment_method_tag = document.querySelector('div#fullScreenPopup2 form div.column p.payment_info');
        payment_method_tag.textContent = "Payment Method: "+payment_method;

        let name_tag = document.querySelector('div#fullScreenPopup2 form p.payment_info + p');
        name_tag.textContent = "Name: "+name;

        const address = document.querySelector('div#fullScreenPopup form input[name=address]').value;
        const city = document.querySelector('div#fullScreenPopup form input[name=city]').value;
        const postal_code = document.querySelector('div#fullScreenPopup form input[name=postal_code]').value;
        const country = document.querySelector('div#fullScreenPopup form select[name=country]').value;

        

        let address_tag = document.querySelector('div#fullScreenPopup2 form div.column p + p');
        address_tag.textContent = "Billing Address: " + address + " " +city + ", "+ postal_code + " " + country;

        const phone = document.querySelector('div#fullScreenPopup form input[name=phone]').value;

        let phone_tag = document.querySelector('div#fullScreenPopup2 form div.column + div.column p.payment_info');
        phone_tag.textContent = "Phone: " + phone;
        
      }
      hideFullScreenPopup.bind(fullScreenPopup)();
      showFullScreenPopup.bind(fullScreenPopup2)();
    });
  });

  let backButtons = document.querySelectorAll('button[name=back]');
  [].forEach.call(backButtons, function(button){
    button.addEventListener('click', function(event){
      event.preventDefault();
      hideFullScreenPopup.bind(fullScreenPopup2)();
      showFullScreenPopup.bind(fullScreenPopup)();
    });
  });

  let cancelButtons = document.querySelectorAll('button[name=cancel]');
  [].forEach.call(cancelButtons, function(button){
    button.addEventListener('click', function(event){
      event.preventDefault();
      hideFullScreenPopup.bind(fullScreenPopup)();
    });
  });

  let cancelButtons2 = document.querySelectorAll('button[name=cancel2]');
  [].forEach.call(cancelButtons2, function(button){
    button.addEventListener('click', function(event){
      event.preventDefault();
      hideFullScreenPopup.bind(fullScreenPopup2)();
    });
  });

  let add_funds_button = document.querySelector('div#fullScreenPopup2 form div.navigation-buttons button + button');
  if(add_funds_button != null){
    add_funds_button.addEventListener('click', updateMoneyRequest);
  }

  /*let addFundsForm = document.querySelector('div#fullScreenPopup form.add_funds_form');
  if(addFundsForm != null){
    addFundsForm.addEventListener('submit', addFundsRequest);
  }*/

  let checkoutForm = document.querySelector('form.checkout');
  if(checkoutForm != null){
    checkoutForm.addEventListener('submit', createPurchaseRequest);
  }

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
  let description = document.querySelector('li textarea[name=description]');
  description.readOnly = !description.readOnly;
  let title = document.querySelector('li textarea[name=title]');
  title.readOnly = !title.readOnly;
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
  let review_id = this.querySelector('input[name=review_id]').value;
  let description = this.querySelector('textarea[name=description]').value;
  let title = this.querySelector('textarea[name=title]').value;
  sendAjaxRequest('put', '/review/'+review_id, {review_id: review_id, description: description, title: title}, reviewHandler);
  event.preventDefault();
}

function updateMoneyRequest(event){
  const add_funds_form = document.querySelector('div#fullScreenPopup form');
  let popup2 = document.querySelector('div#fullScreenPopup2');
  hideFullScreenPopup.bind(popup2)();
  const user_id = add_funds_form.querySelector('input[name=user_id').value;
  if(document.querySelector('input[name=remember]').checked){
    console.log(user_id);
    //sendAjaxRequest('put', '/review/'+review_id, {review_id: review_id, description: description, title: title}, reviewHandler);
  }


  sendAjaxRequest('put', '/wallet/' + user_id + '/add', {money: money}, updateMoneyHandler);
  event.preventDefault();
}


function createPurchaseRequest(event){
  console.log(this);
  /*let review_id = this.querySelector('input[name=review_id]').value;
  let description = this.querySelector('textarea[name=description]').value;
  let title = this.querySelector('textarea[name=title]').value;
  console.log(review_id, description);
  sendAjaxRequest('put', '/review/'+review_id, {review_id: review_id, description: description, title: title}, reviewHandler);*/
  //event.preventDefault();
}


function createReviewRequest(event){
  console.log(this);
  let product_id = this.querySelector('input[name=product_id]').value;
  let user_id = this.querySelector('input[name=user_id]').value;
  let title = this.querySelector('input[name=title]').value;
  let description = this.querySelector('textarea[name=description]').value;
  let rating = this.querySelector('input[name=rating]').value;
  sendAjaxRequest('post', '/review/create/'+user_id, {user_id: user_id, product_id: product_id, title: title, description: description, rating: rating}, reviewCreateHandler);
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
  console.log(this);
  event.preventDefault();
  if (this.querySelector('.heart-button').classList.contains('clicked')) {
    let wishlist_id = this.querySelector('input[name=product_id]').value;
    this.querySelector('.heart-button').classList.remove('clicked')
    console.log("entered delete");
    sendAjaxRequest('delete', '/api/wishlist/'+user_id, {product_id: product_id}, deleteHomeWishlistProductHandler);
  }
  else{
    this.querySelector('.heart-button').classList.add('clicked')
    console.log("entered delete");
    sendAjaxRequest('post', '/api/wishlist/'+user_id, {product_id: product_id}, createCartProductHandler);
  }
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
  let product_id = this.querySelector('input[name=product_id]').value;
  sendAjaxRequest('delete', '/api/wishlist/'+user_id, {product_id: product_id}, deleteWishlistProductHandler);
  event.preventDefault();
}
function deleteCartProductRequest(event){
  let user_id = this.querySelector('input[name=user_id]').value;
  let cart_id = this.querySelector('input[name=cart_id]').value;
  console.log(user_id, cart_id);
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
  if(this.status == 301){
    let response = JSON.parse(this.responseText);
    console.log(response);
  }
  else if(this.status == 200){
    console.log("deleted review");
    let response = JSON.parse(this.responseText);
    let deletion_target = document.querySelector('li[data-id="' + response.review_id + '"]');
    deletion_target.remove();
    console.log(response);
    let user_review_option = document.querySelector('div.user_review_option');

    let image_path = assetBaseUrl + '/' + response.profile_picture;


    user_review_option.innerHTML = `
                    <form class="add_review" method="" action="">
                        <div class = "user_image">
                          <img src ="${image_path}" alt="" />
                        </div>
                        <input type="hidden" name="product_id" value="${response.product_id}" required>
                        <input type="hidden" name="user_id" value="${response.user_id}" required>
                        <label for="title">Title</label>
                        <input id="title" type="text" name="title" required>
                        <label for="description">Description</label>
                        <textarea id="description" type="text" name="description" required> </textarea>
                        <label for="rating">Rating</label>
                        <input id="rating" type="number" name="rating" min="1" max="5" required>
                        <button type="submit" name="add-review" class="button button-outline">
                            Add Review
                        </button>
                    </form>
                              `;

    let reviewCreate1 = document.querySelector('form.add_review');
    reviewCreate1.addEventListener('submit', createReviewRequest);

  }
}

function reviewCreateHandler(){
  if(this.status == 201){
    let user_review_option = document.querySelector('div.user_review_option');
    let response = JSON.parse(this.responseText);
    let image_path = assetBaseUrl + '/' + response.profile_picture;
    user_review_option.innerHTML = `
                            <li class="my-review" data-id="${response.review_id}">
                            <form class="edit_review" method="" action="">
                              <input type="hidden" name="review_id" value="${response.review_id}" required>
                              <strong>${response.date} ${response.title}</strong>
                              <div class = "user_image">
                                <img src ="${image_path}" alt="" />
                              </div>
                              <p class = "user_name"> ${response.name} </p>
                              <label for="title">Title</label>
                              <textarea type="text" name="title" required readonly>${response.title}</textarea>
                              <label for="description">Description</label>
                              <textarea type="text" name="description" required readonly>${response.description}</textarea>
                              ${response.rating}
                              <button type="submit" name="update-review">Save</button>
                              <i class="fas fa-edit"></i>
                            </form>
                            <form class="delete_review" method="" action="">
                              <input type="hidden" name="product_id" value="${response.product_id}" required>
                              <input type="hidden" name="review_id" value="${response.review_id}" required>
                              <button type="submit" name="delete-review" class="button button-outline">Delete Review</button>
                            </form>
                          </li>
                                  `;

    let deleteRev = document.querySelector('form.delete_review');
    deleteRev.addEventListener('submit', deleteReviewRequest);
    let reviewEditIcon2= document.querySelector('li i');
    reviewEditIcon2.addEventListener('click', editReview);
  }
  if(this.status == 301){
    let response = JSON.parse(this.responseText);
    console.log(response);
  }
  
}

function updateMoneyHandler(){
  if(this.status===200){
    let response = JSON.parse(this.responseText);
    document.querySelector('div.user_wallet p + h2').textContent = response.money + response.currencySymbol;
    document.querySelector('p.wallet').textContent = response.money + response.currencySymbol;
    document.querySelector('div.mini-menu ul li:nth-child(4) a').textContent = "Wallet " + response.money + response.currencySymbol;

  }
}

function reviewHandler(){
  if(this.status == 201){
    console.log("reported");
  }
  else if(this.status == 301){
    let response = JSON.parse(this.responseText);
    console.log(response);
  }
  else if(this.status == 200){
    console.log("updated review");
    let reviewEditIcon1= document.querySelector('li i');
    reviewEditIcon1.editReview = editReview.bind(reviewEditIcon1);
    reviewEditIcon1.editReview();
    
  }
}

function createReportHandler(){
  if(this.status == 201){
    console.log("reported");
  }
  if(this.status == 301){
    let response = JSON.parse(this.responseText);
    console.log(response);
  }
}
  
function createCartProductHandler(){
  if(this.status == 201){
    console.log("added to shopping cart");
    
  }
  if(this.status == 301){
    let response = JSON.parse(this.responseText);
    console.log(response);
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
  if(this.status == 301){
    let response = JSON.parse(this.responseText);
    console.log(response);
  }
}

function deleteHomeWishlistProductHandler(){
  if(this.status == 200){
    console.log("removed from wishlist");
  }
  if(this.status == 301){
    let response = JSON.parse(this.responseText);
    console.log(response);
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

function showFullScreenPopup() {
  document.body.classList.add('popup-open');
  this.style.display = 'flex';
  console.log(this);
}

function hideFullScreenPopup() {
  document.body.classList.remove('popup-open');
  this.style.display = 'none';
}



window.onload = function() {
  let forms = document.querySelectorAll('.add_wishlist'); // Select all forms
  if (forms.length === 0) return;
  console.log(forms);
  let user_id = forms[0].querySelector('input[name=user_id]').value;
  // Send an AJAX request to the server to get all the products in the user's wishlist
  fetch('/wishlist/test/' + user_id)
  .then(response => response.json())
  .then(data => {
    forms.forEach(form => {
      let productId = form.querySelector('input[name=product_id]').value; // Get the product id from the form
      // If the product is in the user's wishlist, set the form's action to the remove route
      if (data.wishlist.some(item => item.id == productId)) {
        console.log(form.querySelector('.heart-button'));
        form.querySelector('.heart-button').classList.add('clicked');
      }
    });
  });
}
addEventListeners();
  
  

