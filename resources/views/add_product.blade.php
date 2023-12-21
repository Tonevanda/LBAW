@extends('layouts.app')

@section('content')


<div class = 'product-page'>
  <div class="product-info">
  <div class = "product_img">
  <img src="{{ asset('images/product_images/' . 'default.png') }}">
      </div>
      <div class="product-details">

      <form class = "update_product" method="" action="">
          {{ csrf_field() }}
          <fieldset>
            <legend class="sr-only">Name</legend>
            <b> Name </b><textarea id = "name" placeholder="Enter the book's Author here..."></textarea>
        </fieldset>
          <fieldset>
              <legend class="sr-only">Author</legend>
              <b>Author: </b><textarea id = "author" placeholder="Enter the book's Author here..."></textarea>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Editor</legend>
              <b>Editor: </b><textarea id = "editor" placeholder="Enter the book's Editor here..."></textarea>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Synopsis</legend>
              <b>Synopsis: </b><textarea id = "synopsis" placeholder="Enter the book's Synopsis here..."></textarea>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Language</legend>
              <b>Language: </b><textarea id = "language" placeholder="Enter the book's language here..."></textarea>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Price</legend>
              <b>Price: </b><textarea id = "price" placeholder="Enter the book's Price here..."></textarea>
          </fieldset>
        <button type="button" class="edit_product">
            Edit
        </button>
      </form>
        </div>
  </div>
@endsection