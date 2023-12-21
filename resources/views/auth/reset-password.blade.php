@extends('layouts.app')

@section('content')
<div class="form-page">
  <div class="form-container">
      <h3>Reset Password</h3>
<form method="POST" action="{{ route('password.update') }}">
  {{ csrf_field() }}

  <input type="hidden" name="token" value="{{ $token }}">

  <fieldset>
    <legend class="sr-only">E-Mail Address</legend>
    <label for="email">E-Mail Address</label>
    <input id="email" type="email" name="email" value="{{ request()->email ?? old('email') }}" required autofocus>
    @if ($errors->has('email'))
      <span class="error">
        {{ $errors->first('email') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Password</legend>
    <label for="password">Password</label>
    <input id="password" type="password" name="password" required>
    @if ($errors->has('password'))
      <span class="error">
        {{ $errors->first('password') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Confirm Password</legend>
    <label for="password-confirm">Confirm Password</label>
    <input id="password-confirm" type="password" name="password_confirmation" required>
    @if ($errors->has('password_confirmation'))
      <span class="error">
        {{ $errors->first('password_confirmation') }}
      </span>
    @endif
  </fieldset>

  <button type="submit">
    Reset Password
  </button>

</form>
  </div>
</div>
@endsection
