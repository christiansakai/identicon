defmodule Identicon.Image do
  @moduledoc """
  Module that acts as the Image struct.
  """

  @type t :: %__MODULE__{
    hex: [integer],
    color: {integer, integer, integer},
    grid: [{integer, integer}],
    pixel_map: [{{integer, integer}, {integer, integer}}]
  }

  defstruct hex: nil, 
            color: nil, 
            grid: nil,
            pixel_map: nil
end
