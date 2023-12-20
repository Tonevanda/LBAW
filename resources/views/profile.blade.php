@extends('layouts.app')
@section('content')

@php
$user_info = $user->user()->first();
@endphp

<script>
  var assetBaseUrl = "{{ asset('images/user_images') }}";
</script>

<form class="profile_pic" method="POST" action="{{route('profileImage.update', ['user_id' => $user->user_id])}}" enctype="multipart/form-data">
  {{ csrf_field() }}
  @method('PUT')
  <div class = "user_image">
    <img src ="{{asset('images/user_images/' . $user_info->profile_picture)}}" alt="" />
    <i class="fas fa-edit"></i>
  </div>

  <input type="file" name="profile_picture" hidden>
    @if ($errors->has('profile_picture'))
      <span class="error">
          {{ $errors->first('profile_picture') }}
      </span>
    @endif

    <input type="text" name="old_profile_picture" value="{{ old('profile_picture', $user_info->profile_picture)}}"hidden>

    <input type="text" name="user_id" value="{{ $user->user_id}}" hidden>

    <input type="submit" name="update_pic" value="{{ false }}" hidden>


</form>


<form method="POST" action="{{ route('profile.update', ['user_id' => $user->user_id]) }}">
  {{ csrf_field() }}
  @method('PUT')

    <label for="name">Name</label>
    <input id="name" type="text" name="name" autofocus value="{{ old('name', $user_info->name) }}">
    @if ($errors->has('name'))
      <span class="error">
          {{ $errors->first('name') }}
      </span>
    @endif

    <label for="email">E-Mail</label>
    <input id="email" type="email" name="email" value="{{ old('email',$user_info->email)}}">
    @if ($errors->has('email'))
      <span class="error">
          {{ $errors->first('email') }}
      </span>
    @endif
      
    <label for="address">Address</label>
    <input id="address" type="text" name="address" value="{{ old('address',$user->address)}}">
    @if ($errors->has('address'))
      <span class="error">
          {{ $errors->first('address') }}
      </span>
    @endif
    @if (!Auth::user()->isAdmin()) 
    <label for="password">Old Password</label>
    <input id="old_password" type="password" name="old_password" required>
      @if ($errors->has('old_password'))
        <span class="error">
          This password does not match our records.
        </span>
      @endif
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
    <button type="submit" name="update" value="{{ true }}">
      update
    </button>

</form>
<a class="button" href="{{ route('wishlist',$user->user_id)}}">Wishlist</a>
@endsection