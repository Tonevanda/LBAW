@extends('layouts.app') 

@section('content')


<h2> {{Auth::user()->name}} Account </h2>


<div class = "details_box">

    <i class="fas fa-shopping-cart"></i>

</div>
@endsection