@extends('layouts.app')

@section('content')
<div class="form-page">
  <div class="form-container">
      <h3>Register</h3>
<form method="POST" action="{{ route('register') }}">
    {{ csrf_field() }}

    <label for="name">Name</label>
    <input id="name" type="text" name="name" placeholder="Enter name" value="{{ old('name') }}" required autofocus>
    @if ($errors->has('name'))
      <span class="error">
          {{ $errors->first('name') }}
      </span>
    @endif

    <label for="email">E-Mail Address</label>
    <input id="email" type="email" name="email" placeholder="Enter e-mail address" value="{{ old('email') }}" required>
    @if ($errors->has('email'))
      <span class="error">
          {{ $errors->first('email') }}
      </span>
    @endif

    <label for="password">Password</label>
    <input id="password" type="password" placeholder="Enter password" name="password" required>
    @if ($errors->has('password'))
      <span class="error">
          {{ $errors->first('password') }}
      </span>
    @endif

    <label for="password-confirm">Confirm Password</label>
    <input id="password-confirm" type="password" placeholder="Re-enter password" name="password_confirmation" required>
      <div class="navigation-buttons">
        <a class="button button-outline" href="{{ route('login') }}">Login</a>
        <button type="submit">
      Register
    </button>
  </div>
  </form>
  </div>
</div>
@endsection