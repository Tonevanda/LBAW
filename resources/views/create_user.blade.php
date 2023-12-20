@extends('layouts.app')

@section('content')
<div class="form-page">
  <div class="form-container">
    <h3>New User</h3>
<form method="POST" action="{{ route('user.create') }}">
  {{ csrf_field() }}

  <fieldset>
    <legend class="sr-only">Name</legend>
    <label for="name">Name</label>
    <input id="name" placeholder="Enter name" type="text" name="name" value="{{ old('name') }}" required autofocus>
    @if ($errors->has('name'))
      <span class="error">
        {{ $errors->first('name') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">E-Mail Address</legend>
    <label for="email">E-Mail Address</label>
    <input id="email" placeholder="Enter e-mail address" type="email" name="email" value="{{ old('email') }}" required>
    @if ($errors->has('email'))
      <span class="error">
        {{ $errors->first('email') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Type of User</legend>
    <label for="type">Type of User</label>
    <select name="type">
      <option value="User" {{ old('type') == 'User' ? 'selected' : '' }}>User</option>
      <option value="Admin" {{ old('type') == 'Admin' ? 'selected' : '' }}>Admin</option>
    </select>
  </fieldset>

  <fieldset>
    <legend class="sr-only">Password</legend>
    <label for="password">Password</label>
    <input id="password" placeholder="Enter password" type="password" name="password" required>
    @if ($errors->has('password'))
      <span class="error">
        {{ $errors->first('password') }}
      </span>
    @endif
  </fieldset>

  <fieldset>
    <legend class="sr-only">Confirm Password</legend>
    <label for="password-confirm">Confirm Password</label>
    <input id="password-confirm" placeholder="Re-enter password" type="password" name="password_confirmation" required>
  </fieldset>

  <button type="submit">
    Register
  </button>
</form>
@endsection