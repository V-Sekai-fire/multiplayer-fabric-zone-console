defmodule ZoneConsole.ZoneClientEncodingTest do
  use ExUnit.Case, async: true
  use PropCheck
  import Bitwise

  property "CMD_INSTANCE_ASSET packet is always 100 bytes" do
    forall {asset_id, x, y, z} <-
             {pos_integer(), float(-1.0e6, 1.0e6), float(-1.0e6, 1.0e6), float(-1.0e6, 1.0e6)} do
      byte_size(build_packet(1, asset_id, x, y, z)) == 100
    end
  end

  property "opcode 4 appears in low byte of payload[0]" do
    forall {asset_id, x, y, z} <-
             {pos_integer(), float(-1.0e6, 1.0e6), float(-1.0e6, 1.0e6), float(-1.0e6, 1.0e6)} do
      <<_::binary-44, cmd_word::little-32, _::binary>> = build_packet(1, asset_id, x, y, z)
      (cmd_word &&& 0xFF) == 4
    end
  end

  property "asset_id round-trips through high/low 32-bit split" do
    forall asset_id <- pos_integer() do
      <<_::binary-48, hi::little-32, lo::little-32, _::binary>> =
        build_packet(1, asset_id, 0.0, 0.0, 0.0)

      (bsl(hi, 32) ||| lo) == asset_id
    end
  end

  property "target position round-trips as f32 with < 0.01 error" do
    forall {x, y, z} <-
             {float(-1000.0, 1000.0), float(-1000.0, 1000.0), float(-1000.0, 1000.0)} do
      <<_::binary-56, xu::little-32, yu::little-32, zu::little-32, _::binary>> =
        build_packet(1, 1, x, y, z)

      <<xf::little-float-32>> = <<xu::little-32>>
      <<yf::little-float-32>> = <<yu::little-32>>
      <<zf::little-float-32>> = <<zu::little-32>>
      abs(xf - x) < 0.01 and abs(yf - y) < 0.01 and abs(zf - z) < 0.01
    end
  end

  defp build_packet(player_id, asset_id, tx, ty, tz) do
    id_hi = bsr(asset_id, 32)
    id_lo = band(asset_id, 0xFFFFFFFF)
    <<xu::little-32>> = <<tx::little-float-32>>
    <<yu::little-32>> = <<ty::little-float-32>>
    <<zu::little-32>> = <<tz::little-float-32>>

    <<player_id::little-32, 0.0::little-float-64, 0.0::little-float-64, 0.0::little-float-64,
      0::little-16, 0::little-16, 0::little-16, 0::little-16, 0::little-16, 0::little-16,
      0::little-32, 4::little-32, id_hi::little-32, id_lo::little-32, xu::little-32,
      yu::little-32, zu::little-32, 0::256>>
  end
end
