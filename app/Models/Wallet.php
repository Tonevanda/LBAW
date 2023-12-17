<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    use HasFactory;

    protected $table = 'wallet';

    protected $primaryKey = 'user_id';

    public $timestamps = false;

    protected $fillable = [
        'money',
        'currency_type',
        'transaction_date',
    ];

    public function user()
    {
        return $this->belongsTo(Authenticated::class, 'user_id');
    }

    public function currency()
    {
        return $this->has(Currency::class, 'currency_type');
    }


}
