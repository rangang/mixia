(function() {
  var style = getComputedStyle(document.documentElement);
  var accent = style.getPropertyValue('--accent').trim();
  var accent2 = style.getPropertyValue('--accent2').trim();
  var accent3 = style.getPropertyValue('--accent3').trim();
  var ink = style.getPropertyValue('--ink').trim();
  var muted = style.getPropertyValue('--muted').trim();
  var rule = style.getPropertyValue('--rule').trim();
  var bg2 = style.getPropertyValue('--bg2').trim();

  // --- Chart: Priority Matrix ---
  var chartPriority = echarts.init(document.getElementById('chart-priority'), null, { renderer: 'svg' });
  chartPriority.setOption({
    animation: false,
    tooltip: {
      trigger: 'item',
      appendToBody: true,
      formatter: function(p) {
        return '<strong>' + p.data[3] + '</strong><br/>用户价值: ' + p.data[0] + '<br/>实现成本: ' + p.data[1];
      }
    },
    grid: { top: 30, right: 30, bottom: 50, left: 60 },
    xAxis: {
      name: '用户价值 →',
      nameLocation: 'middle',
      nameGap: 30,
      type: 'value',
      min: 0, max: 10,
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: muted },
      splitLine: { lineStyle: { color: rule, type: 'dashed', opacity: 0.3 } }
    },
    yAxis: {
      name: '← 实现成本',
      nameLocation: 'middle',
      nameGap: 40,
      type: 'value',
      min: 0, max: 10,
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: muted },
      splitLine: { lineStyle: { color: rule, type: 'dashed', opacity: 0.3 } }
    },
    series: [{
      type: 'scatter',
      symbolSize: function(data) { return data[2]; },
      data: [
        [9.5, 2.0, 28, '生物识别解锁'],
        [9.5, 3.5, 28, '密码库加密'],
        [9.0, 3.0, 26, '自动填充'],
        [8.5, 4.0, 24, 'WebDAV同步'],
        [8.5, 4.5, 24, 'SFTP同步'],
        [8.0, 2.5, 22, '密码生成器'],
        [8.0, 3.0, 22, '密钥派生'],
        [7.5, 2.0, 20, '密码条目管理'],
        [7.5, 3.5, 20, '安全审计'],
        [7.0, 2.0, 18, '剪贴板安全'],
        [7.0, 4.0, 18, '导入导出'],
        [6.5, 2.5, 18, '多条目类型'],
        [6.5, 2.0, 16, '收藏与搜索'],
        [6.0, 3.0, 16, '离线模式'],
        [5.5, 4.5, 16, '紧急访问'],
        [5.0, 2.0, 14, '深色模式']
      ],
      itemStyle: {
        color: function(params) {
          var v = params.data[0];
          var c = params.data[1];
          if (v >= 8 && c <= 3) return accent;
          if (v >= 7) return accent3;
          return accent2;
        },
        opacity: 0.85,
        shadowBlur: 10,
        shadowColor: 'rgba(0,0,0,0.3)'
      },
      label: {
        show: true,
        formatter: function(p) { return p.data[3]; },
        position: 'top',
        color: ink,
        fontSize: 11,
        fontWeight: 600
      }
    }]
  });
  window.addEventListener('resize', function() { chartPriority.resize(); });

  // --- Chart: Radar Comparison ---
  var chartRadar = echarts.init(document.getElementById('chart-radar'), null, { renderer: 'svg' });
  chartRadar.setOption({
    animation: false,
    tooltip: {
      trigger: 'item',
      appendToBody: true
    },
    legend: {
      data: ['密匣', 'Bitwarden', '1Password', 'KeePass', 'Enpass'],
      bottom: 0,
      textStyle: { color: muted, fontSize: 12 },
      itemWidth: 18,
      itemHeight: 10
    },
    radar: {
      indicator: [
        { name: '隐私自主', max: 10 },
        { name: '跨平台一致性', max: 10 },
        { name: '移动端体验', max: 10 },
        { name: '生物识别支持', max: 10 },
        { name: '同步灵活性', max: 10 },
        { name: '价格友好', max: 10 },
        { name: '开源透明', max: 10 },
        { name: '企业合规', max: 10 }
      ],
      shape: 'polygon',
      splitNumber: 5,
      axisName: {
        color: ink,
        fontSize: 12,
        fontWeight: 600
      },
      splitLine: {
        lineStyle: { color: rule, opacity: 0.5 }
      },
      splitArea: {
        show: true,
        areaStyle: {
          color: ['rgba(30,41,59,0.3)', 'rgba(30,41,59,0.5)', 'rgba(30,41,59,0.3)', 'rgba(30,41,59,0.5)', 'rgba(30,41,59,0.3)']
        }
      },
      axisLine: {
        lineStyle: { color: rule }
      }
    },
    series: [{
      type: 'radar',
      data: [
        {
          value: [10, 10, 9, 10, 10, 10, 9, 10],
          name: '密匣',
          lineStyle: { color: accent, width: 3 },
          itemStyle: { color: accent },
          areaStyle: { color: accent + '33' }
        },
        {
          value: [6, 5, 8, 9, 6, 7, 10, 5],
          name: 'Bitwarden',
          lineStyle: { color: accent3, width: 2 },
          itemStyle: { color: accent3 },
          areaStyle: { color: accent3 + '22' }
        },
        {
          value: [3, 6, 10, 10, 2, 2, 2, 6],
          name: '1Password',
          lineStyle: { color: '#f472b6', width: 2 },
          itemStyle: { color: '#f472b6' },
          areaStyle: { color: 'rgba(244,114,182,0.13)' }
        },
        {
          value: [10, 3, 3, 3, 5, 10, 10, 7],
          name: 'KeePass',
          lineStyle: { color: accent2, width: 2 },
          itemStyle: { color: accent2 },
          areaStyle: { color: accent2 + '22' }
        },
        {
          value: [3, 5, 7, 8, 4, 5, 2, 4],
          name: 'Enpass',
          lineStyle: { color: muted, width: 2 },
          itemStyle: { color: muted },
          areaStyle: { color: 'rgba(148,163,184,0.13)' }
        }
      ]
    }]
  });
  window.addEventListener('resize', function() { chartRadar.resize(); });
})();
