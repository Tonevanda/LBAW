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

    public function index(Request $request){
        $users = Authenticated::filter($request->input())->paginate(10);
        return view('user_search', ['users' => $users]);
    }

    public function showShoppingCart($user_id){
        $user = Authenticated::findOrFail($user_id);
        return view('shopping_cart', [
            'products' => $user->shoppingCart()->get()
        ]);
    }

    public function showPurchases($user_id){
        $user = Authenticated::findOrFail($user_id);
        return view('purchase_history', [
            'purchases' => $user->purchases()->get()
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
        //dd(request()->all( ));
        $data = request()->validate([
            'profile_picture' => ['required'],
            'name' => 'string|max:250',
            'email' => ['email', 'max:250'],
            'old-password' => 'required|min:8',
            'password' => 'min:8|confirmed',
            'address' => 'string|max:250',
        ]);
        //dd(request('profile_picture'));
        $credentials = [
            'email' => $user->email,
            'password' => $data['old_password']
        ];
        if (Auth::attempt($credentials)) {
            dd('ok');
        }
        //dd(request('profile_picture')->store('uploads', 'public'));
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
