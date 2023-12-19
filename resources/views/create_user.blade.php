@extends('layouts.app')

@section('content')
<div class="form-page">
  <div class="form-container">
      <h3>New User</h3>
<form method="POST" action="{{ route('user.create') }}">
    {{ csrf_field() }}

    <label for="name">Name</label>
    <input id="name" type="text" name="name" value="{{ old('name') }}" required autofocus>
    @if ($errors->has('name'))
      <span class="error">
          {{ $errors->first('name') }}
      </span>
    @endif

    <label for="email">E-Mail Address</label>
    <input id="email" type="email" name="email" value="{{ old('email') }}" required>
    @if ($errors->has('email'))
      <span class="error">
          {{ $errors->first('email') }}
      </span>
    @endif

    <label for="type">Type of User</label>
    <select name="type">
        <option value="User" {{ old('type') == 'User' ? 'selected' : '' }}>User</option>
        <option value="Admin" {{ old('type') == 'Admin' ? 'selected' : '' }}>Admin</option>
    </select>

    <label for="password">Password</label>
    <input id="password" type="password" name="password" required>
    @if ($errors->has('password'))
      <span class="error">
          {{ $errors->first('password') }}
      </span>
    @endif

    <label for="password-confirm">Confirm Password</label>
    <input id="password-confirm" type="password" name="password_confirmation" required>
    <button type="submit">
      Register
    </button>
</form>
@endsection