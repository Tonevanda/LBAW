@extends('layouts.app')

@section('content')

<div class="form-page">
    <div class="form-container">
        <h3>Login</h3>
        <form method="POST" action="{{ route('login') }}">
            {{ csrf_field() }}

            <fieldset>
                <legend class="sr-only">Email</legend>
                <label for="email">E-mail</label>
                <input id="email" type="email" name="email" placeholder="Enter e-mail" values="{{ old('email') }}" required autofocus>
                @if ($errors->has('email'))
                    <span class="error">
                        {{ $errors->first('email') }}
                    </span>
                @endif
            </fieldset>

            <fieldset>
                <legend class="sr-only">Password</legend>
                <label for="password">Password</label>
                <input id="password" type="password" placeholder="Enter password" name="password" required>
                @if ($errors->has('password'))
                    <span class="error">
                        {{ $errors->first('password') }}
                    </span>
                @endif
            </fieldset>

            <a class="blue" href="{{ route('password.request') }}">Forgot Password</a>
            <label>
                <input type="checkbox" name="remember" {{ old('remember') ? 'checked' : '' }}> Remember Me
            </label>

            <div class="navigation-buttons">
                <a class="button button-outline" href="{{ route('register') }}">Register</a>
                <button type="submit">Login</button>
            </div>

            @if (session('success'))
                <p class="success">
                    {{ session('success') }}
                </p>
            @endif
        </form>
    </div>
</div>
@endsection