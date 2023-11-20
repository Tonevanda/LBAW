function addEventListeners() {

    let cartDeleter = document.querySelectorAll('form.remove_cart');
    [].forEach.call(cartDeleter, function(deleter){
      deleter.addEventListener('submit', deleteCartProductRequest);
  });

    let cartCreator = document.querySelectorAll('form.add_cart');
    [].forEach.call(cartCreator, function(creator){
        creator.addEventListener('submit', createCartProductRequest);
    });

    let priceFilter = document.querySelector('form.products_search input[name=price]');
    let priceShow = document.querySelector('form.products_search div');
    if(priceShow.textContent == 0)priceShow.textContent = `no restrictions`;
    priceFilter.addEventListener('input', function () {
      priceShow.textContent = this.value;
      if(priceShow.textContent == 0){
        priceShow.textContent = `no restrictions`;
      }
    });
    
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

  function createCartProductRequest(event){
      let user_id = this.querySelector('input[name=user_id]').value;
      let product_id = this.querySelector('input[name=product_id]').value;

      sendAjaxRequest('post', '/api/shopping-cart/'+user_id, {product_id: product_id}, createCartProductHandler);
      event.preventDefault();
  }
  
  function deleteCartProductRequest(event){
      let user_id = this.querySelector('input[name=user_id]').value;
      let cart_id = this.querySelector('input[name=cart_id]').value;
      //console.log(cart_id);
      sendAjaxRequest('delete', '/api/shopping-cart/'+user_id, {cart_id: cart_id}, deleteCartProductHandler);
      event.preventDefault();
  }


  function createCartProductHandler(){
    if(this.status == 200){
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

  addEventListeners();


 
  