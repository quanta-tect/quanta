//! Stub for wasm32 builds. No hyper dependency.

mod sourced;
pub use sourced::{MetricSource, SourcedCounter, SourcedGauge, SourcedMetric};

pub use prometheus::{
    self,
    core::{
        AtomicF64 as F64, AtomicI64 as I64, AtomicU64 as U64,
        GenericCounter as Counter, GenericCounterVec as CounterVec,
        GenericGauge as Gauge, GenericGaugeVec as GaugeVec,
    },
    exponential_buckets, histogram_opts, linear_buckets,
    Error as PrometheusError, Histogram, HistogramOpts, HistogramVec,
    Opts, Registry,
};

pub fn register<T: Clone + prometheus::core::Collector + 'static>(
    metric: T,
    registry: &Registry,
) -> Result<T, PrometheusError> {
    registry.register(Box::new(metric.clone()))?;
    Ok(metric)
}

#[derive(Debug)]
pub enum Error {
    Io(std::io::Error),
    PortInUse(()),
}

impl From<std::io::Error> for Error {
    fn from(e: std::io::Error) -> Self { Error::Io(e) }
}

pub async fn init_prometheus(_addr: std::net::SocketAddr, _registry: Registry) -> Result<(), Error> {
    Ok(())
}
