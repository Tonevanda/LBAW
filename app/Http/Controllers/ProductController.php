<?php

namespace App\Http\Controllers;

use Illuminate\View\View;
use App\Models\Product;
use Illuminate\Http\Request;
use App\Models\PurchaseProduct;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use App\Events\PriceChange;
use App\Models\Category;

class ProductController extends Controller
{   
    //Show all products
    public function index(Request $request){
        $search_filter = '1 = ?';
        $name_filter = '1';
        $filters = $request->input();
        if(!($filters['price'] ?? false)){
            $filters['price'] = '250';
        }

        if($filters['price'] == 500){
            $filters['price'] = '1000000';
        }


        if($filters['category'] ?? false){
            $category_filter = 'category_type = ?';
        }
        else{
            $category_filter = '1 = ?';
            $filters['category'] = '1';
        }

        if($filters['search'] ?? false){       
            $search_array = array_filter(explode(' ',$filters['search']));
            while(!empty($search_array)){
                $name_filter = implode('&', $search_array).':*';
                $temp_query =  Product::FilterVectors($name_filter);
                array_pop($search_array);        
                if($temp_query->exists())break;
            }
            $search_filter = 'tsvectors @@ to_tsquery(\'english\', ?)';
        };
        $products = Product::Filter($filters, $category_filter, $search_filter, $name_filter)->paginate(12)->appends(request()->query());
        return view('products.index', ['products' => $products]);
    }

    //Show a single product
    public function show($product_id)
    {
        $product = Product::findOrFail($product_id);
        $product = Product::with('productStatistic')->findOrFail($product_id);
        $productRevenue = $product->purchaseProducts->sum('price');
        $reviews = $product->reviews()->get();
    
        return view('products.show', [
            'product' => $product,
            'reviews' => $reviews,
            'statistics' => $product->productStatistic,
            'productRevenue' => $productRevenue,
        ]);
    }

    public function showCreateProductForm(): View
    {
        $categories = Category::all();
        return view('add_product', [
            'categories' => $categories
        ]);
    }

    public function createProduct(Request $request)
    {
        //dd($request);
        $request->validate([
            'image_name' => 'required',
            'name' => 'required|string',
            'synopsis' => 'required|string',
            'price' => 'required|string',
            'stock' => 'required|string',
            'author' => 'string|nullable',
            'editor' => 'string|nullable',
            'language' => 'string|nullable',
            'category' => 'string|nullable'
            #'image' => 'required|string|min:0',
            #'category' => 'required|string|max:250',
        ]);
        $price = preg_replace('/[^0-9]/', '', $request->price);

        $product = Product::create([   
            'name' => $request->name,
            'synopsis' => $request->synopsis,
            'price' => intval($price),
            'stock' => intval($request->stock),
            'author' => $request->author == null ? 'anonymous' : $request->author,
            'editor' => $request->editor == null ? 'self-published' : $request->editor,
            'language' => $request->language == null ? 'english' : $request->language,
            'image' => $request->image_name
            #'image' => $request->image,
            #'category' => $request->category
        ]);

        $product->productCategories()->attach($request->category);

        return redirect()->route('all-products');
    }

    public function updateImage(Request $request){


        $request->file('product_picture')->storeAs('images/product_images', $request->file('product_picture')->getClientOriginalName() ,'public');

        return response()->json($request->file('product_picture')->getClientOriginalName(), 200);
    }

    public function updateProduct(Request $request, $product_id){
        $data = $request->validate([
            'author' => 'required|string|max:250',
            'editor' => 'required|string|max:250',
            'synopsis' => 'required|string|max:250',
            'language' => 'required|string|max:250',
            'price' => 'required|string|min:0',
            #'stock' => 'required|numeric|min:0',
            #'image' => 'required|string|min:0',
            #'category' => 'required|string|max:250',
        ]);
        $data['price'] = str_replace(',', '.', $data['price']);
        $data['price'] = (float) $data['price'];
        $data['price'] =(int)number_format($data['price']*100, 0, ',', '.');
        try{
            $this->authorize('update', Product::class);
        }catch(AuthorizationException $e){
            return redirect()->route('all-products');
        }
        $product=Product::findOrFail($product_id);
        $originalData = $product->toArray();
        $product->update($data);
        $updatedData = $product->toArray();
        if($originalData !== $updatedData){
            event(new PriceChange($product_id));
        }
        return redirect()->route('all-products');
    }

    function change(Request $request) {
        event(new PriceChange($request->id));
    }
}

