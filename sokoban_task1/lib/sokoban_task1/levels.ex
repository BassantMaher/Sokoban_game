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

  @doc """
  Gets the next available level order number.
  Automatically increments from the highest existing order.
  """
  def get_next_level_order do
    case Repo.one(from l in Level, select: max(l.order)) do
      nil -> 1
      max_order -> max_order + 1
    end
  end

  @doc """
  Creates a new level with automatic order assignment if not provided.
  """
  def create_level_with_order(attrs) do
    attrs_with_order =
      if Map.has_key?(attrs, :order) || Map.has_key?(attrs, "order") do
        attrs
      else
        Map.put(attrs, :order, get_next_level_order())
      end

    create_level(attrs_with_order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking level changes.
  """
  def change_level(%Level{} = level, attrs \\ %{}) do
    Level.changeset(level, attrs)
  end
end
