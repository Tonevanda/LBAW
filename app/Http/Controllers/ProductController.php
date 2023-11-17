<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{   
    //Show all products
    public function index(){
        return view('products.index', [
            'products' => Product::Paginate(10)
        ]);
    }

    //Show a single product
    public function show(Product $product){
        return view('products.show', [
            'product' => Product::findOrFail($product->id)
        ]);
    }

}
