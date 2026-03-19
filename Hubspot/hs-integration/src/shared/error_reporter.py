"""
Error and Warning Reporter for HubSpot Integration
Collects, categorizes, and reports execution errors/warnings
"""
from datetime import datetime
from collections import defaultdict
import json
import os
import logging

logger = logging.getLogger(__name__)


class ErrorReporter:
    """Singleton class to collect errors and warnings during execution"""
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ErrorReporter, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
            
        self._initialized = True
        self.start_time = datetime.now()
        self.end_time = None
        
        # Error/Warning storage
        self.errors = []
        self.warnings = []
        
        # Statistics
        self.stats = {
            'customer': {'created': 0, 'updated': 0, 'failed': 0},
            'producer': {'created': 0, 'updated': 0, 'failed': 0},
            'broker': {'created': 0, 'updated': 0, 'failed': 0},
            'quote': {'created': 0, 'updated': 0, 'failed': 0},
            'policy': {'created': 0, 'updated': 0, 'failed': 0},
            'quote_note': {'created': 0, 'updated': 0, 'failed': 0},
            'parent_child_note': {'created': 0, 'updated': 0, 'failed': 0},
            'associations': {
                'created': 0, 'failed': 0,
                'cross_type_conflict': 0,
                'needs_replacement': 0,
                'already_correct': 0,
                'producer_reassigned': 0
            }
        }
        
        # Error categorization
        self.error_categories = defaultdict(list)
        self.warning_categories = defaultdict(list)
    
    def add_error(self, category, message, details=None):
        """Add an error with category and details"""
        error_entry = {
            'timestamp': datetime.now(),
            'category': category,
            'message': message,
            'details': details or {}
        }
        self.errors.append(error_entry)
        self.error_categories[category].append(error_entry)
    
    def add_warning(self, category, message, details=None):
        """Add a warning with category and details"""
        warning_entry = {
            'timestamp': datetime.now(),
            'category': category,
            'message': message,
            'details': details or {}
        }
        self.warnings.append(warning_entry)
        self.warning_categories[category].append(warning_entry)
    
    def update_stats(self, object_type, action, count=1):
        """Update statistics for an object type"""
        if object_type in self.stats:
            if action in self.stats[object_type]:
                self.stats[object_type][action] += count
    
    def finalize(self):
        """Mark execution as complete"""
        self.end_time = datetime.now()
        self._log_association_summary()

    def _log_association_summary(self):
        """Log a detailed association summary at end of run (#3)."""
        assoc_stats = self.stats.get('associations', {})
        created = assoc_stats.get('created', 0)
        failed = assoc_stats.get('failed', 0)
        cross_type = assoc_stats.get('cross_type_conflict', 0)
        needs_replace = assoc_stats.get('needs_replacement', 0)
        already_correct = assoc_stats.get('already_correct', 0)
        producer_reassigned = assoc_stats.get('producer_reassigned', 0)
        total_limit_failures = cross_type + needs_replace

        logger.info('=' * 70)
        logger.info('ASSOCIATION SUMMARY')
        logger.info('=' * 70)
        logger.info(f'  Created successfully:        {created}')
        logger.info(f'  Already correct (skipped):   {already_correct}')
        logger.info(f'  Producer reassignments:      {producer_reassigned}')
        logger.info(f'  Total limit failures:        {total_limit_failures}')
        logger.info(f'    - Cross-type conflicts:    {cross_type}')
        logger.info(f'    - Same-type replacements:  {needs_replace}')
        logger.info(f'  Other failures:              {failed}')

        if total_limit_failures > 0:
            # Break down by association type
            type_breakdown = defaultdict(lambda: {'cross_type': 0, 'needs_replacement': 0})
            for error in self.errors:
                if error['category'] in ('ASSOCIATION_CROSS_TYPE_CONFLICT', 'ASSOCIATION_NEEDS_REPLACEMENT'):
                    assoc_type_id = error.get('details', {}).get('association_type_id', 'unknown')
                    if error['category'] == 'ASSOCIATION_CROSS_TYPE_CONFLICT':
                        type_breakdown[assoc_type_id]['cross_type'] += 1
                    else:
                        type_breakdown[assoc_type_id]['needs_replacement'] += 1

            logger.info(f'  Failures by association type:')
            for type_id, counts in sorted(type_breakdown.items(), key=lambda x: sum(x[1].values()), reverse=True):
                logger.info(
                    f'    Type {type_id}: '
                    f'{counts["cross_type"]} cross-type, '
                    f'{counts["needs_replacement"]} same-type'
                )

            # Top affected objects
            affected_objects = defaultdict(int)
            for error in self.errors:
                if error['category'] in ('ASSOCIATION_CROSS_TYPE_CONFLICT', 'ASSOCIATION_NEEDS_REPLACEMENT'):
                    from_id = error.get('details', {}).get('from_id', 'unknown')
                    from_obj = error.get('details', {}).get('from_object', 'unknown')
                    affected_objects[f'{from_obj}:{from_id}'] += 1

            top_affected = sorted(affected_objects.items(), key=lambda x: x[1], reverse=True)[:10]
            if top_affected:
                logger.info(f'  Top affected objects (up to 10):')
                for obj_key, count in top_affected:
                    logger.info(f'    {obj_key}: {count} failures')

            # Recommendation
            if cross_type > needs_replace:
                logger.info(
                    f'  RECOMMENDATION: {cross_type} failures are cross-type conflicts. '
                    f'Increasing the HubSpot association limit would fix these. '
                    f'REPLACE_ASSOCIATIONS_ON_LIMIT will NOT fix cross-type conflicts.'
                )
            elif needs_replace > 0:
                logger.info(
                    f'  RECOMMENDATION: {needs_replace} failures are same-type conflicts. '
                    f'Setting REPLACE_ASSOCIATIONS_ON_LIMIT=True would fix these.'
                )

        # Cumulative tracking (#5)
        self._log_cumulative_delta(total_limit_failures)

        logger.info('=' * 70)

    def _get_failure_history_path(self):
        """Get path for the cumulative failure history file."""
        import constants
        return os.path.join(getattr(constants, 'log_folder_path', '.'), 'association_failure_history.json')

    def save_failure_history(self):
        """Save current failure counts for cumulative tracking (#5)."""
        history_path = self._get_failure_history_path()
        assoc_stats = self.stats.get('associations', {})
        entry = {
            'timestamp': datetime.now().isoformat(),
            'created': assoc_stats.get('created', 0),
            'failed': assoc_stats.get('failed', 0),
            'cross_type_conflict': assoc_stats.get('cross_type_conflict', 0),
            'needs_replacement': assoc_stats.get('needs_replacement', 0),
            'already_correct': assoc_stats.get('already_correct', 0),
            'total_limit_failures': assoc_stats.get('cross_type_conflict', 0) + assoc_stats.get('needs_replacement', 0)
        }

        history = []
        if os.path.exists(history_path):
            try:
                with open(history_path, 'r') as f:
                    history = json.load(f)
            except (json.JSONDecodeError, IOError):
                history = []

        history.append(entry)
        # Keep last 30 runs
        history = history[-30:]

        try:
            os.makedirs(os.path.dirname(history_path), exist_ok=True)
            with open(history_path, 'w') as f:
                json.dump(history, f, indent=2)
        except IOError as e:
            logger.warning(f'Failed to save failure history: {e}')

    def _log_cumulative_delta(self, current_failures):
        """Log delta compared to previous run (#5)."""
        history_path = self._get_failure_history_path()
        if not os.path.exists(history_path):
            logger.info(f'  Cumulative tracking: First run (no previous data).')
            return

        try:
            with open(history_path, 'r') as f:
                history = json.load(f)
        except (json.JSONDecodeError, IOError):
            return

        if not history:
            return

        prev = history[-1]
        prev_failures = prev.get('total_limit_failures', 0)
        prev_timestamp = prev.get('timestamp', 'unknown')
        delta = current_failures - prev_failures

        if delta > 0:
            logger.warning(
                f'  CUMULATIVE TREND: Association limit failures INCREASED by {delta} '
                f'({prev_failures} -> {current_failures}) since last run ({prev_timestamp}). '
                f'Problem is growing.'
            )
        elif delta < 0:
            logger.info(
                f'  CUMULATIVE TREND: Association limit failures DECREASED by {abs(delta)} '
                f'({prev_failures} -> {current_failures}) since last run ({prev_timestamp}).'
            )
        else:
            logger.info(
                f'  CUMULATIVE TREND: Association limit failures unchanged at {current_failures} '
                f'since last run ({prev_timestamp}).'
            )

        # Show last 5 runs trend if available
        if len(history) >= 2:
            recent = history[-5:]
            trend_values = [r.get('total_limit_failures', 0) for r in recent]
            trend_values.append(current_failures)
            logger.info(f'  Recent trend (last {len(trend_values)} runs): {trend_values}')
    
    def get_duration(self):
        """Get execution duration"""
        end = self.end_time or datetime.now()
        delta = end - self.start_time
        minutes = int(delta.total_seconds() / 60)
        seconds = int(delta.total_seconds() % 60)
        return f"{minutes}m {seconds}s"
    
    def get_status(self):
        """Determine overall execution status"""
        if len(self.errors) > 0:
            # Check if any are critical (not just association limits)
            critical_errors = [e for e in self.errors if e['category'] not in ['ASSOCIATION_LIMIT']]
            if critical_errors:
                return 'FAILED', '❌'
            else:
                return 'SUCCESS_WITH_ERRORS', '⚠️'
        elif len(self.warnings) > 0:
            return 'SUCCESS_WITH_WARNINGS', '⚠️'
        else:
            return 'SUCCESS', '✅'
    
    def get_total_processed(self):
        """Get total records processed"""
        total = 0
        for obj_type, counts in self.stats.items():
            if obj_type != 'associations':
                total += counts.get('created', 0) + counts.get('updated', 0)
        return total
    
    def generate_html_report(self, report_mode='both'):
        """Generate HTML report for email
        
        Args:
            report_mode: 'both', 'statistics_only', or 'errors_only'
        """
        status, status_icon = self.get_status()
        
        # Header
        html = f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }}
        h2 {{ color: #34495e; margin-top: 30px; border-bottom: 2px solid #ecf0f1; padding-bottom: 8px; }}
        .summary {{ background-color: #ecf0f1; padding: 20px; border-radius: 5px; margin: 20px 0; }}
        .summary-item {{ margin: 8px 0; font-size: 16px; }}
        .summary-item strong {{ display: inline-block; width: 180px; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th {{ background-color: #3498db; color: white; padding: 12px; text-align: left; font-weight: bold; }}
        td {{ padding: 10px; border-bottom: 1px solid #ecf0f1; }}
        tr:hover {{ background-color: #f8f9fa; }}
        .error-row {{ background-color: #ffe6e6; }}
        .warning-row {{ background-color: #fff4e6; }}
        .success {{ color: #27ae60; font-weight: bold; }}
        .warning {{ color: #f39c12; font-weight: bold; }}
        .error {{ color: #e74c3c; font-weight: bold; }}
        .status-badge {{ display: inline-block; padding: 5px 15px; border-radius: 20px; font-weight: bold; }}
        .status-success {{ background-color: #d4edda; color: #155724; }}
        .status-warning {{ background-color: #fff3cd; color: #856404; }}
        .status-error {{ background-color: #f8d7da; color: #721c24; }}
        .metric {{ text-align: center; }}
        .metric-value {{ font-size: 24px; font-weight: bold; color: #3498db; }}
        .metric-label {{ font-size: 12px; color: #7f8c8d; text-transform: uppercase; }}
        .footer {{ margin-top: 30px; padding-top: 20px; border-top: 2px solid #ecf0f1; color: #7f8c8d; font-size: 12px; text-align: center; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>{status_icon} HubSpot Integration Execution Report</h1>
        
        <div class="summary">
            <div class="summary-item"><strong>Status:</strong> <span class="status-badge status-{status.lower().replace('_', '-')}">{status.replace('_', ' ')}</span></div>
            <div class="summary-item"><strong>Execution Date:</strong> {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}</div>
            <div class="summary-item"><strong>Duration:</strong> {self.get_duration()}</div>
            <div class="summary-item"><strong>Records Processed:</strong> {self.get_total_processed()}</div>
            <div class="summary-item"><strong>Errors:</strong> <span class="error">{len(self.errors)}</span></div>
            <div class="summary-item"><strong>Warnings:</strong> <span class="warning">{len(self.warnings)}</span></div>
        </div>
"""
        
        # Error Summary Table - Grouped by Type with Counts (conditionally included)
        if report_mode in ['both', 'errors_only'] and self.errors:
            html += """
        <h2>🔴 Error Summary</h2>
        <p style="margin-bottom: 10px; color: #666;">Errors grouped by type with occurrence count</p>
        <table>
            <thead>
                <tr>
                    <th>Error Type</th>
                    <th class="metric">Count</th>
                    <th>Sample Message</th>
                </tr>
            </thead>
            <tbody>
"""
            # Sort by count (descending)
            for category, errors in sorted(self.error_categories.items(), key=lambda x: len(x[1]), reverse=True):
                sample_msg = errors[0]['message'][:150] + '...' if len(errors[0]['message']) > 150 else errors[0]['message']
                html += f"""
                <tr class="error-row">
                    <td><strong>{category.replace('_', ' ').title()}</strong></td>
                    <td class="metric"><span class="metric-value" style="color: #dc3545; font-weight: bold;">{len(errors)}</span></td>
                    <td style="font-size: 12px;">{sample_msg}</td>
                </tr>
"""
            html += """
            </tbody>
        </table>
"""
        
        # Warning Summary Table - Grouped by Type with Counts (conditionally included)
        if report_mode in ['both', 'errors_only'] and self.warnings:
            html += """
        <h2>⚠️ Warning Summary</h2>
        <p style="margin-bottom: 10px; color: #666;">Warnings grouped by type with occurrence count</p>
        <table>
            <thead>
                <tr>
                    <th>Warning Type</th>
                    <th class="metric">Count</th>
                    <th>Sample Message</th>
                </tr>
            </thead>
            <tbody>
"""
            # Sort by count (descending)
            for category, warnings in sorted(self.warning_categories.items(), key=lambda x: len(x[1]), reverse=True):
                sample_msg = warnings[0]['message'][:150] + '...' if len(warnings[0]['message']) > 150 else warnings[0]['message']
                html += f"""
                <tr class="warning-row">
                    <td><strong>{category.replace('_', ' ').title()}</strong></td>
                    <td class="metric"><span class="metric-value" style="color: #ffc107; font-weight: bold;">{len(warnings)}</span></td>
                    <td style="font-size: 12px;">{sample_msg}</td>
                </tr>
"""
            html += """
            </tbody>
        </table>
"""
        
        # Detailed Errors (top 10) - conditionally included
        if report_mode in ['both', 'errors_only'] and self.errors:
            html += """
        <h2>📋 Top 10 Error Details</h2>
        <table>
            <thead>
                <tr>
                    <th>Time</th>
                    <th>Category</th>
                    <th>Message</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
"""
            for error in self.errors[:10]:
                details_str = json.dumps(error['details'], indent=2) if error['details'] else 'N/A'
                html += f"""
                <tr>
                    <td>{error['timestamp'].strftime('%H:%M:%S')}</td>
                    <td><strong>{error['category']}</strong></td>
                    <td>{error['message'][:150]}</td>
                    <td><pre style="font-size: 10px; margin: 0;">{details_str[:200]}</pre></td>
                </tr>
"""
            html += """
            </tbody>
        </table>
"""
        
        # Association Diagnostics section (always show if there are association issues)
        if report_mode in ['both', 'errors_only']:
            html += self.generate_association_summary_html()

        # Object Processing Statistics (conditionally included)
        if report_mode in ['both', 'statistics_only']:
            html += """
        <h2>📊 Object Processing Statistics</h2>
        <table>
            <thead>
                <tr>
                    <th>Object Type</th>
                    <th class="metric">Created</th>
                    <th class="metric">Updated</th>
                    <th class="metric">Failed</th>
                    <th class="metric">Total</th>
                </tr>
            </thead>
            <tbody>
"""
            for obj_type, counts in self.stats.items():
                if obj_type != 'associations':
                    created = counts.get('created', 0)
                    updated = counts.get('updated', 0)
                    failed = counts.get('failed', 0)
                    total = created + updated
                    
                    failed_class = 'error' if failed > 0 else ''
                    
                    html += f"""
                <tr>
                    <td><strong>{obj_type.replace('_', ' ').title()}</strong></td>
                    <td class="metric"><span class="metric-value">{created}</span></td>
                    <td class="metric"><span class="metric-value">{updated}</span></td>
                    <td class="metric"><span class="metric-value {failed_class}">{failed}</span></td>
                    <td class="metric"><span class="metric-value">{total}</span></td>
                </tr>
"""
            
            # Associations
            assoc = self.stats.get('associations', {})
            html += f"""
                <tr>
                    <td><strong>Associations</strong></td>
                    <td class="metric"><span class="metric-value">{assoc.get('created', 0)}</span></td>
                    <td class="metric">-</td>
                    <td class="metric"><span class="metric-value {'error' if assoc.get('failed', 0) > 0 else ''}">{assoc.get('failed', 0)}</span></td>
                    <td class="metric"><span class="metric-value">{assoc.get('created', 0)}</span></td>
                </tr>
"""
            
            html += """
            </tbody>
        </table>
"""
        
        # Footer
        html += f"""
        <div class="footer">
            <p>HubSpot Integration Service | Vault Insurance | Generated at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>
    </div>
</body>
</html>
"""
        
        return html
    
    def save_report(self, output_path, report_mode='both'):
        """Save HTML report to file
        
        Args:
            output_path: Path to save the report
            report_mode: 'both', 'statistics_only', or 'errors_only'
        """
        html = self.generate_html_report(report_mode)
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html)
        
        return output_path
    
    def generate_association_summary_html(self):
        """Generate HTML section for association diagnostics in the email report."""
        assoc_stats = self.stats.get('associations', {})
        created = assoc_stats.get('created', 0)
        failed = assoc_stats.get('failed', 0)
        cross_type = assoc_stats.get('cross_type_conflict', 0)
        needs_replace = assoc_stats.get('needs_replacement', 0)
        already_correct = assoc_stats.get('already_correct', 0)
        producer_reassigned = assoc_stats.get('producer_reassigned', 0)
        total_limit = cross_type + needs_replace

        if total_limit == 0 and failed == 0:
            return ''

        html = """
        <h2>\U0001f517 Association Diagnostics</h2>
        <table>
            <thead>
                <tr>
                    <th>Metric</th>
                    <th class="metric">Count</th>
                    <th>Description</th>
                </tr>
            </thead>
            <tbody>
"""
        rows = [
            ('Created', created, 'Successfully created associations'),
            ('Already Correct', already_correct, 'Skipped — association already exists with correct target'),
            ('Producer Reassigned', producer_reassigned, 'Old producer association deleted and replaced'),
            ('Cross-Type Conflicts', cross_type, 'Different association type occupying the slot (e.g., standard DEAL_TO_CONTACT)'),
            ('Same-Type Replacements Needed', needs_replace, 'Same type exists to different target; needs REPLACE_ASSOCIATIONS_ON_LIMIT=True'),
            ('Other Failures', failed, 'Other association API failures'),
        ]
        for label, count, desc in rows:
            color = '#dc3545' if count > 0 and 'Conflict' in label or 'Failure' in label else '#3498db'
            html += f"""
                <tr>
                    <td><strong>{label}</strong></td>
                    <td class="metric"><span class="metric-value" style="color: {color};">{count}</span></td>
                    <td style="font-size: 12px;">{desc}</td>
                </tr>
"""
        html += """
            </tbody>
        </table>
"""

        # Recommendation
        if cross_type > needs_replace:
            html += f"""
        <p style="background-color: #fff3cd; padding: 10px; border-radius: 5px;">
            <strong>\u26a0\ufe0f Recommendation:</strong> {cross_type} failures are cross-type conflicts.
            Increasing the HubSpot association limit would fix these.
            <code>REPLACE_ASSOCIATIONS_ON_LIMIT</code> will NOT fix cross-type conflicts.
        </p>
"""
        elif needs_replace > 0:
            html += f"""
        <p style="background-color: #fff3cd; padding: 10px; border-radius: 5px;">
            <strong>\u26a0\ufe0f Recommendation:</strong> {needs_replace} failures are same-type conflicts.
            Setting <code>REPLACE_ASSOCIATIONS_ON_LIMIT=True</code> would fix these.
        </p>
"""

        return html

    def reset(self):
        """Reset for new execution (useful for testing)"""
        self.__init__()
