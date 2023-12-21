@extends('layouts.app')

@section('content')

@php
  use App\Models\Category;
@endphp

<div class="form-page">
  <div class="form-container">
      <h3>New Product</h3>
<form method="POST" action="{{ route('product.create') }}">
  {{ csrf_field() }}
  <fieldset>
    <legend class="sr-only">Name</legend>
    <label for="name">Name</label>
    <input id="name" type="text" placeholder="Enter name" name="name" value="{{ old('name') }}" required autofocus>
    @if ($errors->has('name'))
      <span class="error">
        {{ $errors->first('name') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Author</legend>
    <label for="author">Author</label>
    <input id="author" type="text" placeholder="Enter author" name="author" value="{{ old('author') }}" required autofocus>
    @if ($errors->has('author'))
      <span class="error">
        {{ $errors->first('author') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Editor</legend>
    <label for="editor">Editor</label>
    <input id="editor" type="text" placeholder="Enter editor" name="editor" value="{{ old('editor') }}" required autofocus>
    @if ($errors->has('editor'))
      <span class="error">
        {{ $errors->first('editor') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Synopsis</legend>
    <label for="synopsis">Synopsis</label>
    <input id="synopsis" type="text" placeholder="Enter synopsis" name="synopsis" value="{{ old('synopsis') }}" required autofocus>
    @if ($errors->has('synopsis'))
      <span class="error">
        {{ $errors->first('synopsis') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Category</legend>
    <label for="category">Category</label>
    <select name="category">
        @foreach(Category::all() as $category)
            <option value="{{$category->category_type}}" {{ request('category') == $category->category_type ? 'selected' : '' }}>{{$category->category_type}}</option>
        @endforeach
    </select>
  </fieldset>

  <fieldset>
    <legend class="sr-only">Language</legend>
    <label for="language">Language</label>
    <input id="language" placeholder="Enter language" type="text" name="language" value="{{ old('language') }}" required autofocus>
    @if ($errors->has('language'))
      <span class="error">
        {{ $errors->first('language') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Price</legend>
    <label for="price">Price</label>
    <input id="price" type="text" placeholder="Enter price" name="price" value="{{ old('price') }}" required autofocus>
    @if ($errors->has('price'))
      <span class="error">
        {{ $errors->first('price') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Stock</legend>
    <label for="stock">Stock</label>
    <input id="stock" type="text" placeholder="Enter stock" name="stock" value="{{ old('stock') }}" required autofocus>
    @if ($errors->has('stock'))
      <span class="error">
        {{ $errors->first('stock') }}
      </span>
    @endif
  </fieldset>

  <!--
  <fieldset>
    <legend class="sr-only">Year</legend>
    <label for="year">Year</label>
    <input id="year" type="text" name="year" value="{{ old('year') }}" required autofocus>
    @if ($errors->has('year'))
      <span class="error">
        {{ $errors->first('year') }}
      </span>
    @endif
  </fieldset>
  -->

  <button type="submit">
    Submit
  </button>
</form>
  </div>
</div>
@endsection