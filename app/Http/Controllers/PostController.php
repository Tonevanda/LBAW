<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Events\PriceChange;

class PostController extends Controller
{
    function change(Request $request) {
        event(new PriceChange($request->id));
    }

}
