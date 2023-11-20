<?php

use Illuminate\Support\Facades\Route;


use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\AuthenticatedController;
use App\Http\Controllers\PurchaseController;
use Carbon\Carbon;
use App\Models\User;
use GuzzleHttp\Middleware;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

// Pages
Route::controller(ProductController::class)->group(function () {
    Route::get('/', 'index')->name('all-products');
    Route::get('/products/{product_id}', 'show')->name('single-product');
});

#->middleware('admin')
#->middleware('guest')
#->middleware('auth')
// API

Route::controller(AuthenticatedController::class)->group(function () {
    Route::post('/api/shopping-cart/{user_id}', 'store')->name('shopping-cart.store');
    Route::delete('/api/shopping-cart/{user_id}', 'destroy')->name('shopping-cart.destroy');
});
/*
Route::controller(ItemController::class)->group(function () {
    Route::put('/api/cards/{card_id}', 'create');
    Route::post('/api/item/{id}', 'update');
    Route::delete('/api/item/{id}', 'delete');
});
*/

// Authentication
Route::controller(LoginController::class)->group(function () {
    Route::get('/login', 'showLoginForm')->name('login');
    Route::post('/login', 'authenticate');
    Route::get('/logout', 'logout')->name('logout');
});

Route::controller(RegisterController::class)->group(function () {
    Route::get('/register', 'showRegistrationForm')->name('register')->middleware('guest');
    Route::post('/register', 'register');
});


Route::controller(AuthenticatedController::class)->group(function () {
    Route::get('/shopping-cart/{user_id}', 'showShoppingCart')->name('shopping-cart');
    Route::get('/users/{user_id}', 'show')->name('profile');
    Route::get('/user/create', 'showCreateUserForm')->name('create_user');
    Route::post('/user/create', 'create')->name('user.create');
    Route::get('/users', 'index')->name('users');
    Route::put('/users/{user_id}', 'update')->name('profile.update');
    Route::get('/purchase-history/{user_id}', 'showPurchases')->name('purchase_history');
});

Route::controller(PurchaseController::class)->group(function () {
    Route::post('/checkout/{user_id}', 'store')->name('purchase.store');
});

