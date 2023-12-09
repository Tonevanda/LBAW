@extends('layouts.app')

@section('content')




<form method="POST" action="{{ route('product.create') }}">
  {{ csrf_field() }}


  <label for="name">Name</label>
  <input id="name" type="text" name="name" value="{{ old('name') }}" required autofocus>
  @if ($errors->has('name'))
    <span class="error">
      {{ $errors->first('name') }}
    </span>
  @endif

  <label for="synopsis">synopsis</label>
  <input id="synopsis" type="text" name="synopsis" value="{{ old('synopsis') }}" required autofocus>
  @if ($errors->has('synopsis'))
    <span class="error">
      {{ $errors->first('synopsis') }}
    </span>
  @endif

  <label for="price">Price</label>
  <input id="price" type="text" name="price" value="{{ old('price') }}" required autofocus>
  @if ($errors->has('price'))
    <span class="error">
      {{ $errors->first('price') }}
    </span>
  @endif

  <label for="stock">Stock</label>
  <input id="stock" type="text" name="stock" value="{{ old('stock') }}" required autofocus>
  @if ($errors->has('stock'))
    <span class="error">
      {{ $errors->first('stock') }}
    </span>
  @endif

  <label for="author">Author</label>
  <input id="author" type="text" name="author" value="{{ old('author') }}" required autofocus>
  @if ($errors->has('author'))
    <span class="error">
      {{ $errors->first('author') }}
    </span>
  @endif

  <label for="editor">Editor</label>
  <input id="editor" type="text" name="editor" value="{{ old('editor') }}" required autofocus>
  @if ($errors->has('editor'))
    <span class="error">
      {{ $errors->first('editor') }}
    </span>
  @endif

  <!--
  <label for="year">Year</label>
  <input id="year" type="text" name="year" value="{{ old('year') }}" required autofocus>
  @if ($errors->has('year'))
    <span class="error">
      {{ $errors->first('year') }}
    </span>
  @endif
  -->

  <label for="language">Language</label>
  <input id="language" type="text" name="language" value="{{ old('language') }}" required autofocus>
  @if ($errors->has('language'))
    <span class="error">
      {{ $errors->first('language') }}
    </span>
  @endif


  <button type="submit">
    Submit new product
  </button>
</form>
@endsection