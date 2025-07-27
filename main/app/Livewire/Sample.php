<?php

namespace App\Livewire;

use Illuminate\View\View;
use Livewire\Attributes\On;
use Livewire\Component;

class Sample extends Component
{

    #[On('echo:publicChannel,Test')]
    public function echo(): void
    {
        dd('echo');
    }

    public function render(): View
    {
        return view('livewire.sample');
    }
}
