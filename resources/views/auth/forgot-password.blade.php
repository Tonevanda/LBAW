@extends('layouts.app') 

@section('content')
    <form method="POST" action="{{ route('password.email') }}">
        {{ csrf_field() }}
        <div>
            <p>Enter your email address and we'll send you a link to reset your password.</p>
            <label for="email">Email Address</label>
            <input id="email" type="email" name="email" required autofocus>
        </div>
        @if ($errors->has('email'))
            <span class="error">
                {{ $errors->first('email') }}
            </span>
        @endif
        <div>
            <button type="submit">Send Password Reset Link</button>
        </div>
    </form>
@endsection