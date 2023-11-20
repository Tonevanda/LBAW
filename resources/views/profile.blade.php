@extends('layouts.app')

@section('content')
<form method="POST" action="{{ route('profile.update', ['user_id' => Auth::user()->id]) }}" enctype="multipart/form-data">
  {{ csrf_field() }}
  @method('PUT')

  <label for="image">Profile Picture</label>
  
  <input type="file" name="profile_picture" value="{{ old('profile_picture', Auth::user()->profile_picture) }}">
    @if ($errors->has('profile_picture'))
      <span class="error">
          {{ $errors->first('profile_picture') }}
      </span>
    @endif
    <label for="name">Name</label>
    
    <input id="name" type="text" name="name" autofocus value="{{ old('name', Auth::user()->name) }}">
    @if ($errors->has('name'))
      <span class="error">
          {{ $errors->first('name') }}
      </span>
    @endif

    <label for="email">E-Mail</label>
    <input id="email" type="email" name="email" value="{{ old('email',Auth::user()->email)}}">
    @if ($errors->has('email'))
      <span class="error">
          {{ $errors->first('email') }}
      </span>
    @endif

    <label for="address">Address</label>
    <input id="address" type="text" name="address" value="{{ old('address',Auth::user()->authenticated->address)}}">
    @if ($errors->has('address'))
      <span class="error">
          {{ $errors->first('address') }}
      </span>
    @endif

    <label for="password">Old Password</label>
    <input id="old_password" type="password" name="old_password" required>
    @if ($errors->has('old_password'))
      <span class="error">
        This password does not match our records.
      </span>
    @endif

    <label for="password">New Password</label>
    <input id="password" type="password" name="password">
    @if ($errors->has('password'))
      <span class="error">
          {{ $errors->first('password') }}
      </span>
    @endif

    <label for="password-confirm">Confirm Password</label>
    <input id="password-confirm" type="password" name="password_confirmation">
    <button type="submit">
      update
    </button>
</form>
@endsection