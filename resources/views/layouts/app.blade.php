<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <!-- CSRF Token -->
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <title>{{ config('app.name', 'Laravel') }}</title>

        <!-- Styles -->
        <link href="{{ url('css/milligram.min.css') }}" rel="stylesheet">
        <link href="{{ url('css/app.css') }}" rel="stylesheet">
        <script type="text/javascript">
            // Fix for Firefox autofocus CSS bug
            // See: http://stackoverflow.com/questions/18943276/html-5-autofocus-messes-up-css-loading/18945951#18945951
        </script>
        <script type="text/javascript" src={{ url('js/app.js') }} defer>
        </script>
    </head>
    <body>
        <main>
            <header>
                <h1><a href="{{ url('/') }}">Bibliophile's Bliss</a></h1>
                @if (Auth::check())
                    @if (Auth::user()->isAdmin())
                        <a class="button" href="{{ route('users')}}">Users</a>
                        <a class="button" href="{{ route('create_user')}}">Create User</a>
                    @else
                        <a class="button" href="{{ route('profile',Auth::user()->id)}}">{{ Auth::user()->name }}</a>
                        <a class="button" href="{{ route('shopping-cart',Auth::user()->id) }}"> Shopping Cart </a>
                        <a class="button" href="{{ route('purchase_history',Auth::user()->id) }}"> Purchase History </a>
                    @endif
                    <a class="button" href="{{ route('logout') }}"> Logout </a> 
                @else 
                    <a class="button button-outline" href="{{ route('login') }}">Login</a>
                    <a class="button button-outline" href="{{ route('register') }}">Register</a>
                @endif
            </header>
            <section id="content">
                @yield('content')
            </section>
        </main>
    </body>
</html>