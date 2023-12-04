function addEventListeners() {
  let cartDeleter = document.querySelectorAll('form.remove_cart');
  [].forEach.call(cartDeleter, function(deleter){
    deleter.addEventListener('submit', deleteCartProductRequest);
  });

  let cartCreator = document.querySelectorAll('form.add_cart');
  [].forEach.call(cartCreator, function(creator){
    creator.addEventListener('submit', createCartProductRequest);
  });
  /*
  let priceFilter = document.querySelector('form.products_search input[name=price]');
  let priceShow = document.querySelector('form.products_search div');
  if(priceShow.textContent == 0)priceShow.textContent = `no restrictions`;
  priceFilter.addEventListener('input', function () {
    priceShow.textContent = this.value;
    if(priceShow.textContent == 0){
      priceShow.textContent = `no restrictions`;
    }
  });
  */
  
  let reportCreator = document.querySelectorAll('form.report_review');
  [].forEach.call(reportCreator, function(creator){
    creator.addEventListener('submit', createReportRequest);
  });

  let deleteReview = document.querySelectorAll('form.delete_review');
  [].forEach.call(deleteReview, function(deleter){
    deleter.addEventListener('submit', deleteReviewRequest);
  });

  let reviewEditIcon= document.querySelector('li i');
  reviewEditIcon.addEventListener('click', editReview);
  
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
  sendAjaxRequest('delete', '/review/'+review_id, {review_id: review_id, product_id: product_id}, reviewHandler);
  event.preventDefault();
}

function createCartProductRequest(event){
  let user_id = this.querySelector('input[name=user_id]').value;
  let product_id = this.querySelector('input[name=product_id]').value;

  sendAjaxRequest('post', '/api/shopping-cart/'+user_id, {product_id: product_id}, createCartProductHandler);
  event.preventDefault();
}

function deleteCartProductRequest(event){
  let user_id = this.querySelector('input[name=user_id]').value;
  let cart_id = this.querySelector('input[name=cart_id]').value;
  sendAjaxRequest('delete', '/api/shopping-cart/'+user_id, {cart_id: cart_id}, deleteCartProductHandler);
  event.preventDefault();
}

function reviewHandler(){
  console.log(this.status);
  if(this.status == 204){
    console.log("deleted review");
    let response = JSON.parse(this.responseText);
    let deletion_target = document.querySelector('li[data-id="' + response + '"]');
    deletion_target.remove();
  }
  else if(this.status == 201){
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
  
    
  
addEventListeners();


 
  