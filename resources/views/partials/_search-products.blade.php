@php
    use App\Models\Category;
    $user = Auth::user();
    if($user != null && !$user->isAdmin()){
        $auth = $user->authenticated()->first();
        $wallet = $auth->wallet()->first();
        $currency = $wallet->currency()->first();
        $currency_symbol = '€';
    }
    else{
        $currency_symbol = '€';
    }
@endphp

<form class="products_search" action="" method="GET">
    {{ csrf_field() }}
    <fieldset>
        <legend class="sr-only">Search a product:</legend>
        <label for="search">Search a product:</label>
        <input type="text" name="search" placeholder="Enter product" value="{{ request('search') }}">
    </fieldset>
    <fieldset>
        <legend class="sr-only">Select an option:</legend>
        <label for="category">Select an option:</label>
        <select name="category">
            <option value="" {{request('category') == "" ? 'selected' : ''}}>All categories</option>
            @foreach(Category::all() as $category)
                <option value="{{$category->category_type}}" {{ request('category') == $category->category_type ? 'selected' : '' }}>{{$category->category_type}}</option>
            @endforeach
        </select>
    </fieldset>
    <fieldset>
        <legend class="sr-only">Select a price:</legend>
        <label for="price">Select a price:</label>
        <input type="range" name="price" min="1" max="500" step="1" value="{{ request('price') }}">
        <div>
            {{ request('price') == '' ? number_format(250/100, 2, ',', '.') . $currency_symbol : number_format(request('price')/100, 2, ',', '.') . $currency_symbol}}
        </div>
    </fieldset>
    <button type="submit">Search</button>
</form>