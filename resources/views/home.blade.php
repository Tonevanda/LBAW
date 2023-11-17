@extends('layouts.app')

@section('content')

<a class="button button-outline" href="{{ route('login') }}">Login</a>
<a class="button button-outline" href="{{ route('register') }}">Register</a>


@endsection