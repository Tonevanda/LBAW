@extends('layouts.app') 

@section('content')
<div class="form-page">
    <div class="form-container">
        <h3>Forgot Password</h3>
    <form method="POST" action="{{ route('password.email') }}">
        {{ csrf_field() }}
        <fieldset>
            <legend class="sr-only">Email Address</legend>
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
        </fieldset>
        <div>
            <button type="submit">Send Password Reset Link</button>
        </div>
    </form>
    </div>
</div>
@endsection