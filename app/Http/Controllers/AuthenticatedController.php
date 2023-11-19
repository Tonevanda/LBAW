<?php

namespace App\Http\Controllers;

use App\Models\Authenticated;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AuthenticatedController extends Controller
{
    //Show all products in the shopping cart
    public function index($user_id){
        $user = Authenticated::findOrFail($user_id);
        return view('shopping_cart', [
            'products' => $user->shoppingCart()->get()
        ]);
    }
    //Show Profile
    public function show($user_id){
        $user = Authenticated::findOrFail($user_id);
        return view('profile', [
            'user' => $user
        ]);
    }
    public function store(Request $request, $user_id){
        $user = Authenticated::findOrFail($user_id);
        $user->shoppingCart()->attach($request->input('product_id'));
    }
}



//FAZER O PROFILE QUANDO VOLTAR!!