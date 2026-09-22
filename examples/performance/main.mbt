///|
/// Synthetic labels exercise analyzer scale; they are not a real keyboard layout.
fn fixture(shape : String, count : Int) -> String {
  let lines = ["keymap name=synthetic-" + shape]
  for i in 0..<count {
    let key = match shape {
      "dense" => "Ctrl+K"
      "prefix" =>
        if i == 0 {
          "Ctrl+K"
        } else {
          "Ctrl+K,Ctrl+Key" + i.to_string()
        }
      _ => "Ctrl+Key" + i.to_string()
    }
    lines.push(
      "bind b" +
      i.to_string() +
      " command=command." +
      i.to_string() +
      " keys=" +
      key,
    )
  }
  lines.join("\n")
}

///|
fn timing_json(samples : Array[Double]) -> String {
  let mut low = samples[0]
  let mut high = samples[0]
  let mut sum = 0.0
  for value in samples {
    if value < low {
      low = value
    }
    if value > high {
      high = value
    }
    sum += value
  }
  "{\"min_us\":" +
  low.to_string() +
  ",\"mean_us\":" +
  (sum / samples.length().to_double()).to_string() +
  ",\"max_us\":" +
  high.to_string() +
  ",\"samples_us\":[" +
  samples.map(x => x.to_string()).join(",") +
  "]}"
}

///|
fn measure(shape : String, count : Int, repetitions : Int) -> String {
  let source = fixture(shape, count)
  let expected = match shape {
    "dense" => count * (count - 1) / 2
    "prefix" => count - 1
    _ => 0
  }
  // Warm up once, outside the measured samples. Validate semantic work as well.
  let warm = @kit.parse_keymap(source)
  let warm_analysis = @kit.analyze(warm.keymap)
  if !warm.ok || warm_analysis.findings.length() != expected {
    abort("benchmark warmup produced an unexpected result")
  }
  let parse_samples : Array[Double] = []
  let analysis_samples : Array[Double] = []
  let mut observed = 0
  for _ in 0..<repetitions {
    let parse_start = @bench.monotonic_clock_start()
    let parsed = @kit.parse_keymap(source)
    parse_samples.push(@bench.monotonic_clock_end(parse_start))
    let analyze_start = @bench.monotonic_clock_start()
    let result = @kit.analyze(parsed.keymap)
    analysis_samples.push(@bench.monotonic_clock_end(analyze_start))
    observed = result.findings.length()
    if !parsed.ok ||
      parsed.keymap.bindings.length() != count ||
      observed != expected {
      abort("benchmark sample produced an unexpected result")
    }
  }
  "{\"shape\":\"" +
  shape +
  "\",\"bindings\":" +
  count.to_string() +
  ",\"pair_candidates\":" +
  (count * (count - 1) / 2).to_string() +
  ",\"expected_findings\":" +
  expected.to_string() +
  ",\"observed_findings\":" +
  observed.to_string() +
  ",\"parse\":" +
  timing_json(parse_samples) +
  ",\"analyze\":" +
  timing_json(analysis_samples) +
  "}"
}

///|
fn main {
  let quick = @env.args().contains("--quick")
  let repetitions = if quick { 2 } else { 5 }
  let rows : Array[String] = []
  for size in (if quick { [50, 100] } else { [100, 500, 1000] }) {
    rows.push(measure("sparse", size, repetitions))
  }
  rows.push(measure("dense", if quick { 25 } else { 100 }, repetitions))
  rows.push(measure("prefix", if quick { 50 } else { 300 }, repetitions))
  println(
    "{\"benchmark_version\":1,\"clock\":\"monotonic\",\"unit\":\"microseconds\"," +
    "\"warmups_per_case\":1,\"samples_per_case\":" +
    repetitions.to_string() +
    ",\"includes_io_or_startup\":false,\"cases\":[" +
    rows.join(",") +
    "]}",
  )
}
