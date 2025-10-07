defmodule SokobanTask1.Levels do
  @moduledoc """
  The Levels context for managing game levels.
  """

  import Ecto.Query, warn: false
  alias SokobanTask1.Repo
  alias SokobanTask1.Levels.Level

  @doc """
  Returns the list of levels ordered by order field.
  """
  def list_levels do
    from(l in Level, order_by: [asc: l.order])
    |> Repo.all()
  end

  @doc """
  Gets a single level.
  """
  def get_level!(id), do: Repo.get!(Level, id)

  @doc """
  Gets a level by order number.
  """
  def get_level_by_order(order) do
    Repo.get_by(Level, order: order)
  end

  @doc """
  Gets the first level (for starting new games).
  """
  def get_first_level do
    from(l in Level, order_by: [asc: l.order], limit: 1)
    |> Repo.one()
  end

  @doc """
  Creates a level.
  """
  def create_level(attrs \\ %{}) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a level.
  """
  def update_level(%Level{} = level, attrs) do
    level
    |> Level.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a level.
  """
  def delete_level(%Level{} = level) do
    Repo.delete(level)
  end

  @doc """
  Returns the count of levels.
  """
  def count_levels do
    Repo.aggregate(Level, :count, :id)
  end

  @doc """
  Lists levels by difficulty.
  """
  def list_levels_by_difficulty(difficulty) do
    from(l in Level, where: l.difficulty == ^difficulty, order_by: [asc: l.order])
    |> Repo.all()
  end
end
