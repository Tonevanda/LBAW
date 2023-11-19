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
        $data = $request->validate([
            'product_id' => 'required'
        ]);
        $user->shoppingCart()->attach($data['product_id']);
    }

    public function destroy(Request $request, $user_id){
        $user = Authenticated::findOrFail($user_id);
        $data = $request->validate([
            'cart_id' => 'required'
        ]);
        $user->shoppingCart()->wherePivot('id', $data['cart_id'])->detach();
        return response()->json($data['cart_id']);
    }
}



//FAZER O PROFILE QUANDO VOLTAR!!