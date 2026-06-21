//! Stub sourced module

pub trait MetricSource<T> {
    fn collect(&self, metric: &mut T);
}

pub trait SourcedMetric {
    type Metric;
    fn collect(&self) -> Self::Metric;
}

#[derive(Clone, Debug)]
pub struct SourcedCounter<T> {
    inner: T,
}

impl<T> SourcedCounter<T> {
    pub fn new(inner: T) -> Self { Self { inner } }
    pub fn inner(&self) -> &T { &self.inner }
}

#[derive(Clone, Debug)]
pub struct SourcedGauge<T> {
    inner: T,
}

impl<T> SourcedGauge<T> {
    pub fn new(inner: T) -> Self { Self { inner } }
    pub fn inner(&self) -> &T { &self.inner }
}
