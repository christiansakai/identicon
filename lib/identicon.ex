defmodule Identicon do
  @moduledoc """
  Convert a string into a 5x5 pixel
  image that is identically split in the middle.

  First, the string is converted into a list of numbers.
  Then the list of numbers are mapped to
  5 x 5 grid. 
  The way it is mapped is, by mapping the list to
  only the left part 3 x 5 grid, and mirror the 
  rest of the 2 x 5 right part of the grid.
  If the number in the grid is even, we color
  the grid.
  """

  @doc """
  Main function that converts a string
  into an image.
  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
  Convert a string into a list of 16 numbers.
  First, hash the string. Second, convert the
  hash into a list.

  ## Example
    iex> Identicon.hash_input("elixir")
    %Identicon.Image{
      hex: [116, 181, 101, 134, 90, 25, 44, 200, 105, 60, 83, 13, 72, 235, 56, 58]
    }
  """
  @spec hash_input(charlist) :: Identicon.Image.t
  def hash_input(input) do
    hex =
      :md5
      |> :crypto.hash(input)
      |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end

  @doc """
  Add three R, G, B color to Identicon.Image struct.

  ## Example
    iex> Identicon.pick_color(%Identicon.Image{hex: [10, 20, 30, 40, 50]})
    %Identicon.Image{
      hex: [10, 20, 30, 40, 50],
      color: {10, 20, 30}
    }
  """
  @spec pick_color(Identicon.Image.t) :: Identicon.Image.t
  def pick_color(image) do
    %Identicon.Image{hex: [r, g, b | _tail]} = image

    %Identicon.Image{image | color: {r, g, b}}
  end
  
  @doc """
  Change the image.hex from list of 16 numbers into 
  a list 25 numbers indexed.

  ## Example
    iex> image = %Identicon.Image{hex: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]}
    iex> Identicon.build_grid(image)
    %Identicon.Image{
      grid: [{10, 0}, {20, 1}, {30, 2}, {20, 3}, {10, 4}, {40, 5}, {50, 6}, {60, 7}, {50, 8}, {40, 9}, {70, 10}, {80, 11}, {90, 12}, {80, 13}, {70, 14}, {100, 15}, {110, 16}, {120, 17}, {110, 18}, {100, 19}, {130, 20}, {140, 21}, {150, 22}, {140, 23}, {130, 24}],
      hex: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]
    }
  """
  @spec build_grid(Identicon.Image.t) :: Identicon.Image.t
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid = 
      hex
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index
    
    %Identicon.Image{image | grid: grid}
  end

  defp mirror_row([a, b, c]), do: [a, b, c, b, a]

  @doc """
  Filter out two-element-tuple which first element
  of the tuple is an odd integer.

  ## Example
    iex> image = %Identicon.Image{grid: [{10, 0}, {21, 1}, {30, 2}, {21, 3}, {10, 4}, {41, 5}, {50, 6}, {61, 7}, {50, 8}, {41, 9}, {71, 10}, {81, 11}, {91, 12}, {81, 13}, {71, 14}, {101, 15}, {111, 16}, {121, 17}, {111, 18}, {101, 19}, {131, 20}, {141, 21}, {151, 22}, {141, 23}, {131, 24}]}
    iex> Identicon.filter_odd_squares(image)
    %Identicon.Image{
        grid: [{10, 0}, {30, 2}, {10, 4}, {50, 6}, {50, 8}]
    }
  """
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    filtered_grid = 
      grid
      |> Enum.filter(fn {code, _index} -> rem(code, 2) == 0 end)

    %Identicon.Image{image | grid: filtered_grid}
  end

  @doc """
  Create a pixel map data out of image grid data.

  ## Example
    iex> image = %Identicon.Image{grid: [{10, 0}, {30, 2}, {10, 4}, {50, 6}, {50, 8}]}
    iex> Identicon.build_pixel_map(image)
    %Identicon.Image{
      grid: [{10, 0}, {30, 2}, {10, 4}, {50, 6}, {50, 8}],
      pixel_map: [
        {{0, 0}, {50, 50}}, 
        {{100, 0}, {150, 50}}, 
        {{200, 0}, {250,50}},
        {{300, 50}, {350, 100}},
        {{400, 50}, {450, 100}}
        ]
    }
  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = 
      grid
      |> Enum.map(fn {_code, index} ->
        horizontal = rem(index, 50) * 50
        vertical = div(index, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
  Use erlang library to draw an image.
  """
  @spec draw_image(Identicon.Image.t) :: binary
  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    pixel_map
    |> Enum.each(fn {start, stop} -> 
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  @doc """
  Save the drawn image into a file in
  the disk.
  """
  @spec save_image(binary, String.t) :: :ok
  def save_image(image, filename) do
    File.write("#{filename}.png", image)
  end
end
