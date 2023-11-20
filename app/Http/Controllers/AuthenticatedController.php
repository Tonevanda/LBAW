<?php

namespace App\Http\Controllers;

use Illuminate\View\View;
use Illuminate\Http\Request;
use App\Models\Authenticated;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Auth;

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
    //Update Profile
    public function update($user_id){
        $auth = Authenticated::findOrFail($user_id);
        $user = $auth->user()->get()[0];
        #dd('ok');
        dd(request()->all( ));
        $data = request()->validate([
            'name' => 'string|max:250',
            'email' => ['email', 'max:250', Rule::unique('users')->ignore($user->id)],
            'old_password' => 'required|min:8',
            'password' => 'min:8|confirmed',
            'address' => 'string|max:250',
        ]);
        $credentials = [
            'email' => $user->email,
            'password' => $data['old_password']
        ];
        if (Auth::attempt($credentials)) {
            dd('ok');
        }
        $auth->update($data);
        $user->update($data);
        return view('profile', [
            'user' => $auth
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
